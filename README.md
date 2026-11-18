# mkgen

**[Français](#français) | [English](#english)**

---

## Français

`mkgen` génère automatiquement un `Makefile` conforme à la norme 42 pour un projet C.

### Fonctionnalités

- Liste **chaque** `.c` et `.h` explicitement (aucun wildcard).
- **Pas de relink** : chaque `.o` dépend de son `.c`, de tous les `.h` et du `Makefile`.
- Compilation avec `cc -Wall -Wextra -Werror -g3`.
- Règles : `all`, `$(NAME)`, `clean`, `fclean`, `re`, `ac`, `norme`, `valgrind`, `.PHONY`.
- Règle `bonus` ajoutée automatiquement si des fichiers `*_bonus.c` / `*_bonus.h` existent.
- Détection des sous-dossiers ayant leur propre Makefile (ex : `libft`) : compilés avec `make -C` et liés.
- `-I` ajoutés uniquement quand ils sont nécessaires.
- Remplace le `Makefile` existant.

### Installation

```bash
git clone git@github.com:HorusExE69/MKGEN.git
mkdir -p ~/bin && cp MKGEN/mkgen ~/bin/ && chmod +x ~/bin/mkgen
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Nécessite `python3`.

### Utilisation

```bash
mkgen                       # scanne tous les .c/.h du dossier courant (récursif)
mkgen src includes main.c   # scanne seulement ces dossiers / fichiers
mkgen -o obj                # les .o vont dans obj/ (créé s'il n'existe pas)
mkgen src inc -o obj        # combinable
mkgen -n libft.a            # génère une bibliothèque (ar rcs)
mkgen -b checker            # binaire bonus séparé (défaut : même nom que NAME)
mkgen -h                    # aide
```

| Option | Description |
|---|---|
| `-o dossier` | Dossier de sortie des `.o` |
| `-n nom` | Nom du programme (défaut : nom du dossier courant). Un nom en `.a` produit une lib |
| `-b nom` | Nom du binaire bonus |

### Règles du Makefile généré

| Règle | Effet |
|---|---|
| `make` / `make all` | Compile le programme |
| `make bonus` | Compile la partie bonus |
| `make clean` | Supprime les `.o` |
| `make fclean` | `clean` + supprime le binaire |
| `make re` | `fclean` puis `all` |
| `make ac` | `all` puis `clean` |
| `make norme` | `norminette -R CheckForbiddenSourceHeader` sur tous les fichiers |
| `make valgrind ARGS="..."` | Lance le programme sous valgrind (fuites, fds, origines) |

### Bonus

- Un fichier `x_bonus.c` remplace `x.c` dans la compilation bonus.
- Si un fichier bonus contient un `main`, le `main` obligatoire est exclu du bonus.
- Les autres fichiers sont partagés.

### Sécurité / erreurs gérées

mkgen refuse (sans rien écrire) : `-o` sans valeur, options inconnues ou dupliquées, chemins inexistants ou hors du projet, dossier `-o` qui contient des sources ou qui est `.` (le `rm -rf` de `clean` les supprimerait), fichiers avec espaces ou caractères spéciaux, aucun `.c` trouvé, nom invalide.
Il avertit en cas de `main` absent ou multiple, d'include introuvable, ou de fichier `makefile` qui masquerait le `Makefile`.

---

## English

`mkgen` automatically generates a 42-norm compliant `Makefile` for a C project.

### Features

- Lists **every** `.c` and `.h` explicitly (no wildcards).
- **No relink**: each `.o` depends on its `.c`, every `.h` and the `Makefile`.
- Compiles with `cc -Wall -Wextra -Werror -g3`.
- Rules: `all`, `$(NAME)`, `clean`, `fclean`, `re`, `ac`, `norme`, `valgrind`, `.PHONY`.
- A `bonus` rule is added automatically when `*_bonus.c` / `*_bonus.h` files exist.
- Detects sub-directories with their own Makefile (e.g. `libft`): built with `make -C` and linked.
- `-I` flags are only added when actually needed.
- Overwrites the existing `Makefile`.

### Installation

```bash
git clone git@github.com:HorusExE69/MKGEN.git
mkdir -p ~/bin && cp MKGEN/mkgen ~/bin/ && chmod +x ~/bin/mkgen
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Requires `python3`.

### Usage

```bash
mkgen                       # scan every .c/.h in the current directory (recursive)
mkgen src includes main.c   # scan only these directories / files
mkgen -o obj                # put .o files in obj/ (created if missing)
mkgen src inc -o obj        # can be combined
mkgen -n libft.a            # build a static library (ar rcs)
mkgen -b checker            # separate bonus binary (default: same as NAME)
mkgen -h                    # help
```

| Option | Description |
|---|---|
| `-o dir` | Output directory for `.o` files |
| `-n name` | Program name (default: current directory name). A `.a` name builds a library |
| `-b name` | Bonus binary name |

### Generated Makefile rules

| Rule | Effect |
|---|---|
| `make` / `make all` | Build the program |
| `make bonus` | Build the bonus part |
| `make clean` | Remove `.o` files |
| `make fclean` | `clean` + remove the binary |
| `make re` | `fclean` then `all` |
| `make ac` | `all` then `clean` |
| `make norme` | `norminette -R CheckForbiddenSourceHeader` on every file |
| `make valgrind ARGS="..."` | Run the program under valgrind (leaks, fds, origins) |

### Bonus

- A `x_bonus.c` file replaces `x.c` in the bonus build.
- If a bonus file defines `main`, the mandatory `main` is left out of the bonus build.
- Every other file is shared.

### Safety / error handling

mkgen refuses (and writes nothing) on: `-o` without a value, unknown or repeated options, missing paths or paths outside the project, an `-o` directory that contains sources or is `.` (the `rm -rf` in `clean` would delete them), file names with spaces or special characters, no `.c` found, invalid names.
It warns about a missing or duplicate `main`, unresolved includes, or a lowercase `makefile` that would shadow the `Makefile`.
