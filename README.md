# pandoc-bts-sio

Dépôt regroupant le modèle Word (`.dotx`), le filtre Lua et la configuration pandoc utilisés pour générer les documents BTS SIO, avec un script d'installation pour Windows et Linux.

L'objectif : pouvoir taper `pandoc -d bts-sio -o sortie.docx source.md` **depuis n'importe quel dossier, sur n'importe laquelle de tes machines**, sans jamais répéter les options `--reference-doc`, `--lua-filter`, `-V lang=fr-FR`.

---

## 1. Comprendre pandoc avant de comprendre le dépôt

Cette section explique le vocabulaire pandoc utilisé plus bas. Si tu connais déjà ces notions, passe directement à la [section 2](#2-structure-du-dépôt).

### 1.1 Le « data dir » (répertoire de données utilisateur)

Pandoc a un dossier bien à lui, sur chaque machine, où il va chercher automatiquement des fichiers de configuration : modèles, filtres, styles par défaut. Ce dossier s'appelle le **data dir** (ou « user data directory »).

Son emplacement dépend de l'OS :

| OS | Emplacement par défaut |
|---|---|
| Linux | `~/.local/share/pandoc` |
| Windows | `%APPDATA%\pandoc` (c'est-à-dire `C:\Users\<toi>\AppData\Roaming\pandoc`) |

Tu peux toujours vérifier l'emplacement réel avec :

```
pandoc --version
```

qui affiche une ligne du type `User data directory: /home/toi/.local/share/pandoc`.

**Pourquoi ce dossier existe :** sans lui, tu devrais toujours donner un chemin complet à pandoc (`--reference-doc=/chemin/absolu/vers/modele.dotx`). Avec lui, tu peux ranger tes fichiers une fois pour toutes à un endroit que pandoc connaît déjà, et n'utiliser que des noms courts.

**Important : ce dossier n'existe pas tout seul.** Pandoc ne le crée jamais lui-même — c'est à toi de le créer et d'y déposer des fichiers si tu veux t'en servir. C'est exactement le rôle du script d'installation de ce dépôt : créer ce dossier (s'il n'existe pas) et y placer/relier tes fichiers.

### 1.2 Le fichier « defaults » (fichier de configuration pandoc)

Un **defaults file** est un fichier YAML qui regroupe des options de ligne de commande, pour éviter de les retaper à chaque fois. Par exemple, au lieu de :

```
pandoc --reference-doc=modele.dotx --lua-filter=linebreak.lua -V lang=fr-FR -o sortie.docx source.md
```

tu écris ces mêmes options une fois dans un fichier `bts-sio.yaml` :

```yaml
reference-doc: modele.dotx
filters:
  - linebreak.lua
variables:
  lang: fr-FR
```

et tu appelles ensuite juste :

```
pandoc -d bts-sio -o sortie.docx source.md
```

Pandoc va chercher un fichier nommé `bts-sio.yaml` (l'extension `.yaml` est ajoutée automatiquement) à deux endroits, dans cet ordre :
1. le dossier courant ;
2. le sous-dossier `defaults/` du data dir (voir §1.1).

C'est le point 2 qui nous intéresse : si `bts-sio.yaml` est dans `<data dir>/defaults/`, la commande `pandoc -d bts-sio` fonctionne **depuis n'importe quel dossier**, pas seulement depuis celui où se trouve le fichier.

### 1.3 La notation `${.}` : le point qui inquiète

Dans un defaults file, quand tu écris un chemin vers un autre fichier (le modèle `.dotx`, le filtre `.lua`), il faut préciser *par rapport à quoi* ce chemin est relatif. Trois options existent :

- un chemin **absolu** (`C:/Users/toi/modele.dotx`) : fonctionne, mais différent sur chaque machine, illisible, à retaper si tu changes de PC ;
- un chemin relatif au **dossier de travail courant** (celui d'où tu lances la commande pandoc) : fragile, ça casse dès que tu lances la commande depuis un autre dossier ;
- `${.}` : une notation spéciale qui **se substitue automatiquement par le dossier où se trouve le fichier `.yaml` lui-même**, au moment où pandoc le lit.

Concrètement, si `bts-sio.yaml` est situé dans `<data dir>/defaults/`, alors `${.}` vaut `<data dir>/defaults` — peu importe d'où tu as lancé pandoc, et peu importe la machine. C'est ce qui rend le chemin **portable** : le même fichier `bts-sio.yaml`, copié tel quel sur ton PC Windows et ta machine Linux du lycée, pointera correctement vers les fichiers voisins sur chacune des deux machines, sans qu'on ait besoin de le modifier.

Dans notre fichier, on écrit donc :

```yaml
reference-doc: ${.}/../reference-docs/modele-pandoc.dotx
```

Ce qui se lit : « en partant du dossier où est ce fichier `.yaml` (`${.}`), remonte d'un niveau (`..`), puis descends dans `reference-docs/`, et prends `modele-pandoc.dotx` ». Cette navigation par `../` fonctionne uniquement parce qu'on a organisé volontairement les sous-dossiers du data dir en miroir de ceux du dépôt git (voir §2) — le fichier `.yaml` et le dossier `reference-docs/` sont toujours voisins, où qu'ils soient copiés.

### 1.4 Le filtre Lua (`--lua-filter`)

Un filtre Lua est un petit script qui modifie le document pendant la conversion (ici : gestion des retours à la ligne). Il se déclare avec `--lua-filter=chemin/vers/fichier.lua`, ou dans un defaults file avec la clé `filters:`.

Détail pratique : si un filtre est rangé dans le sous-dossier `filters/` du data dir, pandoc le retrouve **juste avec son nom**, même sans passer par un defaults file. C'est une astuce de secours utile pour tester rapidement un filtre en ligne de commande sans configuration :

```
pandoc --lua-filter=linebreak.lua -o out.docx in.md
```

### 1.5 Le modèle de référence (`--reference-doc`)

C'est le fichier `.dotx`/`.docx` dont pandoc récupère uniquement les **styles** (polices, couleurs, marges, styles de titres...) — jamais le contenu du fichier. C'est ce qui donne son identité visuelle (violet/bleu, Source Sans 3, JetBrains Mono) à tous les documents générés.

---

## 2. Structure du dépôt

```
pandoc-bts-sio/
├── README.md
├── .gitattributes
├── .gitignore
├── reference-docs/
│   ├── modele-pandoc.dotx
│   └── pandoc-reference-bts-sio-v2.docx
├── filters/
│   └── linebreak.lua
├── defaults/
│   └── bts-sio.yaml
└── install/
    ├── install.sh          # Linux / WSL
    └── install.ps1         # Windows
```

- **`reference-docs/`** : les modèles Word (styles uniquement).
- **`filters/`** : les scripts Lua.
- **`defaults/`** : les fichiers de configuration pandoc (celui qui relie tout).
- **`install/`** : les scripts qui « branchent » ce dépôt sur le data dir de pandoc.

Ce dépôt reste toujours le seul endroit où tu modifies quoi que ce soit (modèle, filtre, config). Le data dir de pandoc, lui, ne contiendra jamais que des **liens** vers ce dépôt — jamais de copies. Ça veut dire qu'un `git pull` suffit à mettre à jour toutes tes machines : pas besoin de relancer le script d'installation à chaque changement (seulement la première fois sur une machine donnée, ou si tu ajoutes un nouveau sous-dossier).

### Le fichier `defaults/bts-sio.yaml`

```yaml
# Usage : pandoc -d bts-sio -o sortie.docx source.md
reference-doc: ${.}/../reference-docs/modele-pandoc.dotx
filters:
  - ${.}/../filters/linebreak.lua
variables:
  lang: fr-FR
```

---

## 3. Installation

### 3.1 Sous Linux / WSL

```bash
git clone <url-du-depot> ~/dev/pandoc-bts-sio
cd ~/dev/pandoc-bts-sio
chmod +x install/install.sh
./install/install.sh
```

Le script :
1. demande à pandoc lui-même où se trouve son data dir (via `pandoc --version`), pour éviter tout chemin faux codé en dur ;
2. crée ce dossier s'il n'existe pas encore ;
3. crée, pour chacun des trois dossiers (`reference-docs`, `filters`, `defaults`), un **lien symbolique** depuis le data dir vers le dossier correspondant du dépôt ;
4. si un dossier du même nom existe déjà à cet endroit et n'est pas déjà un lien, il est renommé (`.bak.AAAAMMJJHHMMSS`) plutôt qu'écrasé, par sécurité.

### 3.2 Sous Windows

```powershell
git clone <url-du-depot> C:\dev\pandoc-bts-sio
cd C:\dev\pandoc-bts-sio
powershell -ExecutionPolicy Bypass -File install\install.ps1
```

Même logique, mais avec des **jonctions** (`New-Item -ItemType Junction`) plutôt que des liens symboliques : elles ne nécessitent ni droits administrateur ni mode développeur, contrairement aux vrais liens symboliques Windows.

⚠️ Un bug connu de pandoc fait que `pandoc --version` affiche parfois `AppData\Roaming\pandoc` alors que certaines installations (notamment via WinGet) écrivent réellement ailleurs. Comme le script utilise la valeur annoncée par pandoc lui-même plutôt qu'un chemin figé, il reste cohérent avec ce que pandoc va effectivement chercher — mais si quelque chose semble ne pas fonctionner, vérifie `pandoc --version` en premier.

### 3.3 Vérifier que l'installation a fonctionné

```
pandoc -d bts-sio -o test.docx test.md
```

Si `test.docx` est généré avec les bons styles, tout est en place.

---

## 4. Utilisation au quotidien

Depuis n'importe quel dossier, sur n'importe laquelle des deux machines :

```
pandoc -d bts-sio -o sujets/Table-Conversion-Points.docx sujets/Table-Conversion-Points.md
```

Pour ajouter des options ponctuelles (elles s'ajoutent à celles du defaults file, sans les remplacer) :

```
pandoc -d bts-sio --toc -o sortie.docx source.md
```

---

## 5. Faire évoluer le modèle ou le filtre

- **Nouvelle version du modèle** (ex. `pandoc-reference-bts-sio-v3.docx`) : ajoute le nouveau fichier dans `reference-docs/`, puis change une seule ligne dans `defaults/bts-sio.yaml` (`reference-doc: ...`). L'ancienne version reste disponible dans l'historique git et dans le dossier, au cas où.
- **Nouveau filtre Lua** : ajoute le fichier dans `filters/`, ajoute une ligne dans la liste `filters:` du defaults file.
- **Nouveau besoin de configuration différente** (ex. un modèle pour un autre type de document) : crée un second fichier dans `defaults/`, par exemple `defaults/bts-sio-lettre.yaml`, appelable avec `pandoc -d bts-sio-lettre`.

Dans tous les cas : modifie uniquement le dépôt git, puis `git pull` sur l'autre machine. Comme le data dir ne contient que des liens vers le dépôt, rien d'autre à faire.

---

## 6. Dépannage

| Symptôme | Piste |
|---|---|
| `pandoc -d bts-sio` dit qu'il ne trouve pas le fichier | Vérifier que l'installation a bien créé les liens : `ls -la <data dir>` (Linux) ou `Get-Item <data dir>\defaults` (Windows), la propriété `LinkType` doit être renseignée |
| Le modèle Word ne semble pas appliqué | Vérifier que `reference-doc:` pointe vers le bon fichier, et que c'est bien un `.dotx`/`.docx` produit à partir d'un export pandoc modifié (pas un document Word classique) |
| Le filtre Lua ne semble pas s'exécuter | Tester en direct : `pandoc --lua-filter=linebreak.lua -o out.docx in.md` depuis le dossier `filters/` du dépôt, pour isoler si le problème vient du filtre ou de la configuration |
| Sous Windows, le script d'install échoue silencieusement | Relancer avec `powershell -ExecutionPolicy Bypass -File install\install.ps1` et lire le message d'erreur affiché |

---

## 7. Utiliser le modèle et le filtre dans Typora et Obsidian

Typora et Obsidian ne savent pas lire `.dotx` nativement : les deux délèguent l'export `.docx` au pandoc installé sur la machine. Concrètement, ça veut dire que le principe est le même que pour la ligne de commande (section 4) — il suffit de dire à l'appli d'ajouter `-d bts-sio` aux arguments qu'elle transmet à pandoc. Pandoc ne fait pas de différence entre un appel lancé par toi dans un terminal et un appel lancé en coulisses par Typora ou Obsidian : il va chercher `bts-sio.yaml` dans le data dir (§1.2) exactement pareil.

⚠️ Prérequis : l'installation (section 3) doit avoir été faite sur la machine utilisée, sinon `-d bts-sio` ne trouvera rien.

### 7.1 Typora

1. `Fichier` → `Préférences` → `Export`.
2. Dans la section « Autres options pandoc » (« Other Pandoc Options »), champ « Arguments supplémentaires » (« Append Extra Arguments ») : ajoute

   ```bash
   -d bts-sio
   ```

3. Exporte ensuite normalement via `Fichier` → `Exporter` → `Word (.docx)`.

Si une version de Typora n'accepte pas `-d` (à vérifier au cas par cas), remplace par les deux options explicites, avec le chemin réel du data dir sur ta machine (§1.1) :

```
--reference-doc=/home/toi/.local/share/pandoc/reference-docs/modele-pandoc.dotx --lua-filter=/home/toi/.local/share/pandoc/filters/linebreak.lua
```

(sous Windows, adapter en `--reference-doc=%APPDATA%\pandoc\reference-docs\modele-pandoc.dotx --lua-filter=%APPDATA%\pandoc\filters\linebreak.lua` — si les variables d'environnement ne sont pas interprétées par Typora, écris le chemin complet en dur).

### 7.2 Obsidian

Obsidian n'a pas d'export pandoc intégré : il faut un plugin communautaire qui l'appelle à ta place. Deux options équivalentes, au choix :

| Plugin | Où le trouver |
|---|---|
| **Pandoc Plugin** (OliverBalfour) | `Paramètres` → `Plugins communautaires` → `Parcourir`, rechercher « Pandoc » |
| **Enhancing Export** (mokeyish) | même chemin, rechercher « Enhancing Export » |

Une fois le plugin installé et activé :

1. Dans ses réglages, renseigne le chemin de l'exécutable pandoc si demandé (`which pandoc` sous Linux/WSL, `where.exe pandoc` sous Windows).
2. Dans le champ des arguments pandoc supplémentaires (« Extra Pandoc Arguments » ou équivalent selon le plugin), ajoute

   ```bash
   -d bts-sio
   ```

3. Exporte via la palette de commandes (`Ctrl+P` / `Cmd+P`) puis choisis l'export Word (.docx) proposé par le plugin.

Comme pour Typora, si `-d` n'est pas reconnu par le plugin, utilise directement `--reference-doc=...` et `--lua-filter=...` avec les chemins complets vers le data dir.
