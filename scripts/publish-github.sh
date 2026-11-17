#!/usr/bin/env bash
#
# Publica o projeto no GitHub.
#
#   bash scripts/publish-github.sh
#
# O script é idempotente: pode ser executado de novo sem duplicar nada.
# A visibilidade, o branch e a mensagem de commit podem ser sobrescritos pelo
# ambiente:
#
#   VISIBILITY=private BRANCH=main bash scripts/publish-github.sh
#
# Requisitos: `git`, `gh` (autenticado) e, opcionalmente, GIT_NAME / GIT_EMAIL
# para commitar sem configuracao global de identidade.

set -euo pipefail

REPO_SLUG="${REPO_SLUG:-GuilhermeQuerque/Servidor_celular_de_baixo_consumo_energetico}"
REMOTE_URL="https://github.com/${REPO_SLUG}.git"
BRANCH="${BRANCH:-main}"
VISIBILITY="${VISIBILITY:-public}"
DESCRIPTION="${DESCRIPTION:-Energia e custo de um servidor de armazenamento pessoal: celular Android medido vs. armazenamento em nuvem modelado.}"

COMMIT_MSG="${COMMIT_MSG:-Cria a constitution v3 do experimento

Especifica o experimento de medicao de energia de um servidor de
armazenamento pessoal: o celular Android como candidato medido e a
nuvem como candidato modelado a partir dos dados publicados dos
provedores.

- specs/mission.md: por que o estudo existe, o que e perguntado e a
  derivacao completa da amostra bruta ate o numero publicado
- specs/techstack.md: com o que se mede, o contrato de dados e o
  registro de premissas
- specs/roadmap.md: a ordem do trabalho, fase por fase, com criterios
  de entrada e de saida
- AGENTS.md: as perguntas de pesquisa, na forma original
- README.md: a apresentacao do projeto
- .gitignore: ignora a configuracao local do Claude Code e os artefatos
  regeneraveis da campanha; o manifesto com os SHA-256 e versionado
- scripts/publish-github.sh: publica o repositorio no GitHub

Co-Authored-By: Claude Code <noreply@anthropic.com>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

falha() { echo "ERRO: $*" >&2; exit 1; }

# --- 1. Pre-requisitos -------------------------------------------------------

command -v git >/dev/null 2>&1 || falha "git nao encontrado no PATH"
command -v gh  >/dev/null 2>&1 || falha "gh nao encontrado no PATH (https://cli.github.com)"

gh auth status >/dev/null 2>&1 || falha "gh nao autenticado — rode: gh auth login"

[ -f "specs/mission.md" ] || falha "isto nao parece a raiz do projeto (falta specs/mission.md)"

echo "==> projeto:       $ROOT"
echo "==> destino:      https://github.com/$REPO_SLUG"
echo "==> branch:       $BRANCH"
echo "==> visibilidade: $VISIBILITY"

# --- 2. Identidade do commit -------------------------------------------------

if ! git config --get user.email >/dev/null 2>&1 && [ -z "${GIT_EMAIL:-}" ]; then
  falha "git sem user.email configurado — rode:
    git config user.name  'Seu Nome'
    git config user.email 'seu@email'
  ou exporte GIT_EMAIL=... e GIT_NAME=... antes de chamar este script."
fi

# --- 3. Repositorio local ----------------------------------------------------

if [ ! -d ".git" ]; then
  echo "==> inicializando o repositorio git (branch: $BRANCH)"
  git init -b "$BRANCH" 2>/dev/null || { git init; git checkout -b "$BRANCH"; }
else
  CURRENT="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  if [ "$CURRENT" != "$BRANCH" ]; then
    if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
      git checkout "$BRANCH"
    else
      git checkout -b "$BRANCH"
    fi
  fi
fi

# --- 4. Guarda de publicacao -------------------------------------------------
# O repositorio e publico: nada de configuracao local da maquina pode vazar.

if git check-ignore -q .claude/settings.local.json 2>/dev/null; then
  echo "==> ok: .claude/settings.local.json esta ignorado"
else
  falha ".claude/settings.local.json NAO esta ignorado — um repositorio publico
  vazaria a configuracao local do Claude Code. Revise o .gitignore antes de
  continuar."
fi

# --- 5. Commit ---------------------------------------------------------------

git add -A

if git diff --cached --quiet; then
  echo "==> nada a commitar — a arvore ja esta limpa"
else
  echo "==> commitando"
  if git config --get user.email >/dev/null 2>&1; then
    git commit -m "$COMMIT_MSG"
  else
    GIT_AUTHOR_NAME="${GIT_NAME:-Guilherme Querque}" GIT_AUTHOR_EMAIL="$GIT_EMAIL" \
    GIT_COMMITTER_NAME="${GIT_NAME:-Guilherme Querque}" GIT_COMMITTER_EMAIL="$GIT_EMAIL" \
      git commit -m "$COMMIT_MSG"
  fi
fi

# --- 6. Remoto ---------------------------------------------------------------

git remote remove origin >/dev/null 2>&1 || true

if gh repo view "$REPO_SLUG" >/dev/null 2>&1; then
  echo "==> o repositorio ja existe no GitHub — reaproveitando"
  git remote add origin "$REMOTE_URL"
else
  echo "==> criando o repositorio no GitHub ($VISIBILITY)"
  gh repo create "$REPO_SLUG" \
    --"$VISIBILITY" \
    --description "$DESCRIPTION" \
    --source=. \
    --remote=origin
  git remote set-url origin "$REMOTE_URL"
fi

# --- 7. Push -----------------------------------------------------------------

echo "==> enviando para o GitHub"
git push -u origin "$BRANCH"

echo
echo "Pronto: https://github.com/$REPO_SLUG"
