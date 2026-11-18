#!/bin/sh
# **************************************************************************** #
#  install.sh - installe mkgen / installs mkgen                                #
#                                                                              #
#  ./install.sh               copie mkgen dans ~/bin et ajoute ~/bin au PATH   #
#  ./install.sh --alias       copie mkgen et cree un alias a la place du PATH  #
#  ./install.sh --dir DIR     installe dans DIR au lieu de ~/bin               #
#  ./install.sh --uninstall   desinstalle (binaire + lignes du .zshrc/.bashrc) #
# **************************************************************************** #

set -eu

MARK_BEGIN="# >>> mkgen >>>"
MARK_END="# <<< mkgen <<<"
MODE="path"
ACTION="install"
DIR="$HOME/bin"

die() { printf 'install.sh: erreur : %s\n' "$1" >&2; exit 1; }
info() { printf 'install.sh: %s\n' "$1"; }

usage() {
	cat <<'EOF'
usage : ./install.sh [--alias] [--dir DIR] [--uninstall]

  (sans option)  copie mkgen dans ~/bin et ajoute ~/bin au PATH
  --alias        cree un alias mkgen au lieu de modifier le PATH
  --dir DIR      dossier d'installation (defaut : ~/bin)
  --uninstall    supprime mkgen et les lignes ajoutees aux fichiers du shell
  -h, --help     affiche cette aide

Relancer le script met a jour l'installation sans dupliquer les lignes.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--alias) MODE="alias" ;;
		--uninstall) ACTION="uninstall" ;;
		--dir)
			[ $# -ge 2 ] || die "il manque le dossier apres --dir"
			[ -n "$2" ] || die "dossier vide apres --dir"
			DIR="$2"
			shift ;;
		-h|--help) usage; exit 0 ;;
		*) die "option inconnue '$1' (./install.sh --help)" ;;
	esac
	shift
done

case "$DIR" in
	/*) ;;
	*) DIR="$(pwd)/$DIR" ;;
esac
case "$DIR" in
	*\"*|*\$*|*\`*|*\\*) die "le dossier ne doit pas contenir \" \$ \` ou \\" ;;
esac

# fichiers de config du shell a modifier : celui du shell courant + ceux existants
rc_files() {
	shell_name="$(basename "${SHELL:-sh}")"
	case "$shell_name" in
		zsh) main_rc="$HOME/.zshrc" ;;
		bash) main_rc="$HOME/.bashrc" ;;
		*) main_rc="$HOME/.profile" ;;
	esac
	printf '%s\n' "$main_rc"
	for f in "$HOME/.zshrc" "$HOME/.bashrc"; do
		[ "$f" != "$main_rc" ] && [ -f "$f" ] && printf '%s\n' "$f"
	done
	return 0
}

# supprime le bloc mkgen d'un fichier (en gardant le fichier, ses droits, ses liens)
remove_block() {
	f="$1"
	[ -f "$f" ] || return 0
	grep -qF "$MARK_BEGIN" "$f" || return 0
	tmp="$(mktemp "${TMPDIR:-/tmp}/mkgen.XXXXXX")" || die "mktemp a echoue"
	awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
		$0 == b { skip = 1; next }
		$0 == e { skip = 0; next }
		!skip { print }
	' "$f" > "$tmp" || { rm -f "$tmp"; die "impossible de lire $f"; }
	cat "$tmp" > "$f" || { rm -f "$tmp"; die "impossible d'ecrire $f"; }
	rm -f "$tmp"
}

add_block() {
	f="$1"
	[ -e "$f" ] && [ ! -f "$f" ] && die "$f existe mais n'est pas un fichier"
	if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then
		printf '\n' >> "$f" || die "impossible d'ecrire $f"
	fi
	{
		printf '%s\n' "$MARK_BEGIN"
		if [ "$MODE" = "alias" ]; then
			printf 'alias mkgen="python3 \\"%s/mkgen\\""\n' "$DIR"
		else
			printf 'case ":$PATH:" in\n'
			printf '\t*":%s:"*) ;;\n' "$DIR"
			printf '\t*) export PATH="%s:$PATH" ;;\n' "$DIR"
			printf 'esac\n'
		fi
		printf '%s\n' "$MARK_END"
	} >> "$f" || die "impossible d'ecrire $f"
}

if [ "$ACTION" = "uninstall" ]; then
	if [ -f "$DIR/mkgen" ]; then
		rm -f "$DIR/mkgen" || die "impossible de supprimer $DIR/mkgen"
		info "supprime : $DIR/mkgen"
	else
		info "$DIR/mkgen n'existe pas (deja supprime ?)"
	fi
	for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
		if [ -f "$f" ] && grep -qF "$MARK_BEGIN" "$f"; then
			remove_block "$f"
			info "lignes mkgen retirees de $f"
		fi
	done
	info "desinstalle. Ouvre un nouveau terminal (ou: unalias mkgen 2>/dev/null)."
	exit 0
fi

# --- installation ---------------------------------------------------------
SRC_DIR="$(cd "$(dirname "$0")" && pwd)" || die "dossier du script introuvable"
SRC="$SRC_DIR/mkgen"
[ -f "$SRC" ] || die "mkgen introuvable a cote de install.sh ($SRC)"
command -v python3 >/dev/null 2>&1 \
	|| die "python3 est introuvable : mkgen en a besoin"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 6))' \
	|| die "python3 >= 3.6 est requis"

if [ -e "$DIR" ] && [ ! -d "$DIR" ]; then
	die "$DIR existe et n'est pas un dossier"
fi
mkdir -p "$DIR" || die "impossible de creer $DIR"
if [ -d "$DIR/mkgen" ]; then
	die "$DIR/mkgen est un dossier"
fi
if [ "$SRC" != "$DIR/mkgen" ]; then
	# copie via un fichier temporaire : pas de mkgen a moitie copie
	cp "$SRC" "$DIR/.mkgen.tmp" || die "copie impossible vers $DIR"
	chmod 755 "$DIR/.mkgen.tmp" || die "chmod impossible"
	mv -f "$DIR/.mkgen.tmp" "$DIR/mkgen" || die "installation impossible dans $DIR"
fi
info "installe : $DIR/mkgen"

rc_files | while IFS= read -r f; do
	remove_block "$f"
	add_block "$f"
	if [ "$MODE" = "alias" ]; then
		info "alias ajoute dans $f"
	else
		info "$DIR ajoute au PATH dans $f"
	fi
done

info "termine ! Ouvre un nouveau terminal ou lance :  source $(rc_files | head -n 1)"
info "puis :  mkgen -h"
