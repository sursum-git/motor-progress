#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${ROOT_DIR}/web/"
QUERY_SOURCE_DIR="${ROOT_DIR}/sursum-api/querys/"
DEST_HOST="${DEPLOY_HOST:-192.168.0.39}"
DEST_PORT="${DEPLOY_PORT:-22}"
DEST_USER="${DEPLOY_USER:-suporte_ima}"
DEST_PATH="${DEPLOY_PATH:-/var/www/clients/client1/web7/web/query-progress/}"
STRICT_HOST_KEY_CHECKING="${STRICT_HOST_KEY_CHECKING:-accept-new}"
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        *)
            echo "Uso: $0 [--dry-run]" >&2
            exit 1
            ;;
    esac
done

if ! command -v rsync >/dev/null 2>&1; then
    echo "rsync nao encontrado." >&2
    exit 1
fi

if ! command -v sshpass >/dev/null 2>&1; then
    echo "sshpass nao encontrado." >&2
    exit 1
fi

if [[ -z "${DEPLOY_PASSWORD:-}" ]]; then
    echo "Defina DEPLOY_PASSWORD com a senha do servidor." >&2
    exit 1
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
    echo "Diretorio web nao encontrado: ${SOURCE_DIR}" >&2
    exit 1
fi

RSYNC_ARGS=(
    -rltDzv
    --delete
    --omit-dir-times
    --no-perms
    --no-owner
    --no-group
    --exclude=.git/
    --exclude=.codex/
    --exclude=.agents/
    --exclude='sursum-conf/*.sqlite-shm'
    --exclude='sursum-conf/*.sqlite-wal'
    --exclude='sursum-conf/*.sqlite.lock'
)

if [[ "$DRY_RUN" -eq 1 ]]; then
    RSYNC_ARGS+=(--dry-run)
fi

SSH_COMMAND="ssh -p ${DEST_PORT} -o StrictHostKeyChecking=${STRICT_HOST_KEY_CHECKING}"

echo "Sincronizando ${SOURCE_DIR} -> ${DEST_USER}@${DEST_HOST}:${DEST_PATH}"
sshpass -p "${DEPLOY_PASSWORD}" rsync "${RSYNC_ARGS[@]}" -e "${SSH_COMMAND}" "${SOURCE_DIR}" "${DEST_USER}@${DEST_HOST}:${DEST_PATH}"

if [[ -d "${QUERY_SOURCE_DIR}" ]]; then
    QUERY_RSYNC_ARGS=(-rltDzv --delete --omit-dir-times --no-perms --no-owner --no-group)
    if [[ "$DRY_RUN" -eq 1 ]]; then
        QUERY_RSYNC_ARGS+=(--dry-run)
    fi
    echo "Sincronizando consultas salvas ${QUERY_SOURCE_DIR} -> ${DEST_USER}@${DEST_HOST}:${DEST_PATH%/}/sursum-querys/"
    sshpass -p "${DEPLOY_PASSWORD}" rsync "${QUERY_RSYNC_ARGS[@]}" -e "${SSH_COMMAND}" "${QUERY_SOURCE_DIR}" "${DEST_USER}@${DEST_HOST}:${DEST_PATH%/}/sursum-querys/"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
    echo "Ajustando permissoes do SQLite no destino"
    REMOTE_CONF_DIR="${DEST_PATH%/}/sursum-conf"
    REMOTE_QUERY_DIR="${DEST_PATH%/}/sursum-querys"
    PERM_COMMAND=$(printf "mkdir -p %q %q && chgrp -R www-data %q && chmod 2775 %q && find %q -maxdepth 1 -type f \\( -name '*.sqlite' -o -name '*.sqlite-wal' -o -name '*.sqlite-shm' -o -name '*.sqlite.lock' \\) -exec chmod 0664 {} + && printf 'Require all denied\\n' > %q" \
        "${REMOTE_CONF_DIR}" "${REMOTE_QUERY_DIR}" "${REMOTE_CONF_DIR}" "${REMOTE_CONF_DIR}" "${REMOTE_CONF_DIR}" "${REMOTE_QUERY_DIR}/.htaccess")
    SUDO_COMMAND=$(printf "sudo -S sh -c %q" "${PERM_COMMAND}")
    printf '%s\n' "${DEPLOY_PASSWORD}" | sshpass -p "${DEPLOY_PASSWORD}" ssh -p "${DEST_PORT}" -o "StrictHostKeyChecking=${STRICT_HOST_KEY_CHECKING}" "${DEST_USER}@${DEST_HOST}" "${SUDO_COMMAND}"
fi
