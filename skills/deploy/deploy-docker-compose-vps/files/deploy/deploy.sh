#!/usr/bin/env bash
# <APP> on its server, run as root from the folder it lives in (/srv/<APP>):
#
#   deploy.sh setup                           once, by hand: folders, settings, certificates, nginx
#   deploy.sh <production|staging> <commit>   puts a commit's image to work (its full SHA)
#
# The image brings what runs it on a server (deploy/ in the repository). Every deploy takes this
# script, the Compose file and the environment's nginx site from the image of the commit it deploys,
# so a change to them arrives with it, and a rollback takes the older ones back. Nothing is copied
# here by hand.
#
# A deploy runs the commit's migrations on their own, then starts its app and worker, and waits
# until the app answers healthy as the image's own build; a failed migration leaves what ran before
# running. A rollback is a deploy of the commit before: the migrations don't go back, which is why
# they're written expand/contract (compose.yaml).
#
# The deploy workflow's SSH key runs this and nothing else, with an environment and a commit
# (authorized_keys names it as the key's command), so the key can't do more than start an image CI
# published.
#
# Mind: the deploy that brings a new version of this script still runs the old one (the one on the
# server is what the key runs); the new one takes over from the next deploy. So whatever a new
# compose.yaml needs must work without what only the new script would write (compose.yaml's header).
set -euo pipefail

# --- This app's settings --------------------------------------------------------------------------
# The image, lowercase as GHCR wants it.
image="ghcr.io/<ORG>/<APP>"
# Each environment's address, Compose project and the loopback port nginx finds its app on. The
# ports must be ones nothing else on the host uses (`ss -ltn`).
production_address="<DOMAIN>"
staging_address="staging.<DOMAIN>"
production_project="<APP>"
staging_project="<APP>-staging"
production_port=3200
staging_port=3201
# The Compose profiles a new environment starts besides the app and the database: `worker`, or empty.
profiles="worker"
# --------------------------------------------------------------------------------------------------

home=$(dirname "$(readlink -f "$0")")
nginx=/etc/nginx
certificates=/etc/letsencrypt/live

usage() {
  echo "Usage: deploy.sh setup | deploy.sh <production|staging> <commit, its full SHA>" >&2
  exit 2
}

if [[ $image$production_address$staging_address$production_project$staging_project == *"<"* ]]; then
  echo "deploy.sh: fill in the app's settings at its top first." >&2
  exit 1
fi

address_of() { if [[ $1 == production ]]; then echo "$production_address"; else echo "$staging_address"; fi; }
project_of() { if [[ $1 == production ]]; then echo "$production_project"; else echo "$staging_project"; fi; }
port_of() { if [[ $1 == production ]]; then echo "$production_port"; else echo "$staging_port"; fi; }

random_hex() { head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
random_base64() { head -c 32 /dev/urandom | base64 | tr -d '\n'; }

# The files the image of `tag` brings for running it, in a new folder the caller removes.
files_of() {
  local folder container
  folder=$(mktemp -d)
  container=$(docker create "$image:$1")
  docker cp --quiet "$container:/app/deploy/." "$folder"
  docker rm "$container" >/dev/null
  echo "$folder"
}

# Puts `from` at `to` with `mode`, unless it's there already: as a new file moved over the old, so
# this script, while it runs, keeps reading the copy it started with (bash reads a script as it
# goes; one overwritten in place would run half of each). Fails when nothing changed.
place() {
  local from=$1 to=$2 mode=$3
  if [[ -e $to ]] && cmp -s "$from" "$to"; then return 1; fi
  install -m "$mode" "$from" "$to.new"
  mv "$to.new" "$to"
}

# An environment's settings (deploy/.env.example), made on its first deploy with secrets of its own.
# The app's own settings are then added there by hand.
ensure_settings() {
  local environment=$1 file=$home/$1/.env
  [[ -e $file ]] && return
  (
    umask 077
    cat >"$file" <<EOF
COMPOSE_PROJECT_NAME=$(project_of "$environment")
APP_PORT=$(port_of "$environment")
APP_TAG=
COMPOSE_PROFILES=$profiles
POSTGRES_PASSWORD=$(random_hex)
AUTH_SECRET=$(random_base64)
APP_URL=https://$(address_of "$environment")
EOF
  )
  echo "$environment: made $file with secrets of its own; add the app's own settings there."
}

# Adds `name=value` to a settings file where it has no value yet; one that's there stays (a secret
# data was written with must never change behind its back). How a release that needs a new setting
# gives it to servers set up before it, from the deploy after the one that brings this script.
ensure_setting() {
  local file=$1 name=$2 value=$3
  grep -q "^$name=." "$file" && return
  (
    umask 077
    # The empty line .env.example has, if any: taken out, the value added.
    sed -i "/^$name=/d" "$file"
    printf '%s=%s\n' "$name" "$value" >>"$file"
  )
  echo "Added $name to $file."
}

# The environment's nginx site, rendered from the image's template, once its certificate exists.
# A site nginx refuses goes back to the one before, so one bad file never takes the host's other
# sites down with it.
update_site() {
  local files=$1 environment=$2 address site current
  address=$(address_of "$environment")
  site=$address.conf
  [[ -e $certificates/$address/fullchain.pem ]] || return 0
  sed -e "s/__DOMAIN__/$address/g" -e "s/__APP_PORT__/$(port_of "$environment")/g" \
    "$files/nginx/site.conf" >"$files/$site"
  current=$nginx/sites-available/$site
  if [[ -e $current ]]; then cp -p "$current" "$files/$site.before"; fi
  if place "$files/$site" "$current" 644 || [[ ! -e $nginx/sites-enabled/$site ]]; then
    ln -sfn "$current" "$nginx/sites-enabled/$site"
    if nginx -t 2>/dev/null; then
      systemctl reload nginx
    else
      if [[ -e $files/$site.before ]]; then mv "$files/$site.before" "$current"; else rm -f "$current" "$nginx/sites-enabled/$site"; fi
      echo "$environment: nginx refused the new $site, so the one before stays: $(nginx -t 2>&1 | tail -1)" >&2
      exit 1
    fi
  fi
}

# Once, by hand: the folders, both environments' settings, certificates and sites. Running it again
# changes only what's missing or new.
setup() {
  install -d -m 750 "$home" "$home/production" "$home/staging"
  # main's newest, pulled first: a copy of it left from before would otherwise be used.
  docker pull --quiet "$image:main" >/dev/null
  local files environment address
  files=$(files_of main)
  place "$files/deploy.sh" "$home/deploy.sh" 755 || true
  for environment in production staging; do
    address=$(address_of "$environment")
    place "$files/compose.yaml" "$home/$environment/compose.yaml" 644 || true
    ensure_settings "$environment"
    # Needs the address's DNS pointing here first.
    [[ -e $certificates/$address/fullchain.pem ]] || certbot certonly --nginx --non-interactive -d "$address"
    update_site "$files" "$environment"
  done
  rm -rf "$files"
  echo "Set up. Next: the deploy key in root's authorized_keys, then GitHub's secret and variables."
}

deploy() {
  local environment=$1 commit=$2
  [[ -d $home/$environment ]] || { echo "No $home/$environment: run deploy.sh setup first." >&2; exit 1; }
  cd "$home/$environment"

  # A commit no Release ran for has no image: this fails with "not found".
  docker pull --quiet "$image:$commit" >/dev/null
  local files
  files=$(files_of "$commit")
  place "$files/compose.yaml" compose.yaml 644 || true
  place "$files/deploy.sh" "$home/deploy.sh" 755 || true
  # Other files the image carries for the server (a backup script, say) are placed here the same way.
  update_site "$files" "$environment"
  rm -rf "$files"
  ensure_settings "$environment"
  # Settings later releases need go here, each added where it's missing, e.g.
  #   ensure_setting .env SOME_SECRET "$(random_hex)"

  local port before build worker
  port=$(sed -n 's/^APP_PORT=//p' .env)
  before=$(sed -n 's/^APP_TAG=//p' .env)
  before=${before:-nothing}
  # The commit the image says it was built from (Dockerfile): this one, or for a commit that changed
  # nothing in the image, the one whose image it reuses (release.yml). The health check must name it.
  build=$(docker image inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$image:$commit" | sed -n 's/^BUILD_COMMIT=//p')

  # Says what went wrong, with the last of the named services' logs.
  failed() {
    echo "$environment: $1 Before: $before." >&2
    if [[ $# -gt 1 ]]; then docker compose logs --tail 40 "${@:2}" >&2; fi
    exit 1
  }

  # Compose takes the tag from here over the one in .env, which keeps naming what ran before until
  # the new one started.
  export APP_TAG=$commit
  # The migrations alone first: if they fail, what ran before keeps running.
  docker compose run --rm -T migrate || failed "$commit's migrations didn't run through; nothing else changed."
  docker compose up -d --remove-orphans || failed "$commit didn't start." app
  sed -i "s/^APP_TAG=.*/APP_TAG=$commit/" .env

  # Up to two minutes for the app to answer: its database reachable, and as the new build, so the
  # container before can't pass for it.
  healthy() {
    local answer
    answer=$(curl -fsS -m 5 "http://127.0.0.1:$port/api/health" 2>/dev/null) || return 1
    [[ $answer == *'"database":"ok"'* ]] || return 1
    [[ -z $build || $answer == *"\"build\":\"$build\""* ]]
  }
  for _ in $(seq 60); do
    healthy && break
    sleep 2
  done
  healthy || failed "$commit didn't answer healthy as build ${build:-?} within two minutes." app
  # The health check's word on the worker can still be the one before's heartbeat: this one has to
  # be running, and never have stopped. -a, as one restarting in a loop isn't "running".
  worker=$(docker compose ps -a -q worker 2>/dev/null || true)
  if [[ -n $worker ]]; then
    [[ $(docker inspect -f '{{.State.Running}} {{.RestartCount}}' "$worker") == "true 0" ]] ||
      failed "$commit's worker keeps stopping." worker
  fi

  echo "$environment runs $commit (build ${build:-unknown}). Before: $before."
  # A step for staging alone after a good deploy (bringing its made-up data up to date, say) goes
  # here, behind [[ $environment == staging ]], so it can never run in production.

  # Old images go, but for the newest five and those running: a rollback to one needs no pull.
  docker image ls "$image" --format '{{.Repository}}:{{.Tag}}' | tail -n +6 |
    xargs -r docker image rm >/dev/null 2>&1 || true
}

# Over SSH, the arguments come as the command the workflow asked for, which isn't run as such: it's
# read as words and checked here, and only a deploy is let through, never the setup.
from_ssh=false
if [[ $# -eq 0 && -n ${SSH_ORIGINAL_COMMAND:-} ]]; then
  read -r -a words <<<"$SSH_ORIGINAL_COMMAND"
  set -- "${words[@]}"
  from_ssh=true
fi
case "${1:-}" in
  setup)
    [[ $# -eq 1 && $from_ssh == false ]] || usage
    setup
    ;;
  production | staging)
    [[ $# -eq 2 && $2 =~ ^[0-9a-f]{40}$ ]] || usage
    deploy "$1" "$2"
    ;;
  # Further commands the key may run (starting staging's made-up data over, say) go here, each
  # checked as strictly as these.
  *) usage ;;
esac
