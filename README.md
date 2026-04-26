# nyaa-hs

Unofficial scraper library for [nyaa.si](https://nyaa.si) and [sukebei.nyaa.si](https://sukebei.nyaa.si), written in Haskell.

## Install

### Library

With `stack`, add to `stack.yaml`:

```yaml
extra-deps:
  - git: https://github.com/Twigums/nyaa-hs
    commit: 3cf06aa29954f4b7a580d7d902e62962dedca949
```

### CLI

```bash
git clone https://github.com/Twigums/nyaa-hs && cd ./nyaa-hs
stack install
```

## CLI Usage

```
$ stack exec nyaa
Usage: nyaa {site} {command} {args}

Sites {site: optional}:
  nyaa (default; sfw)
  sukebei (nsfw)

Commands {command: required} {args: optional/required}:
  last {n}                         Last `n` uploads (`n`: optional)
  search {keyword} {page} {--all}  Search by `keyword` on `page`, defaulted to trusted-only or all torrents if `--all` is provided (`keyword`: required; `page`, `--all`: optional)
  get {id}                         View details of torrent given `id` (`id`: required)
  user {name} {lim}                View uploads by user limited to `lim` items (`name`: required; `lim`: optional)

Examples:
  nyaa search "attack on titan"          -> Returns trusted-only torrent information for "attack on titan"
  nyaa search "attack on titan" --all    -> Returns all torrent information for "attack on titan" (no filter)
  nyaa nyaa last 10                      -> Returns the last 10 uploads on nyaa
  nyaa sukebei search foo 2              -> Returns all available torrent information on page 2 of sukebei for "foo"
  nyaa get 111                           -> Returns torrent information on torrent with `id = 111`
  nyaa user Twigums 67                   -> Returns, at most, 67 torrent items by `user = Twigums`
```

Output is JSON on stdout. Errors print to stderr with non-zero exit.

## Library Usage

```haskell
import Nyaa
import Nyaa.Types
import Nyaa.Site.Nyaa as Nyaa
```

### Search

```haskell
results <- search NyaaSi (defaultSearchParams "no game no life")

let params = defaultSearchParams "gushing over magical girls"
               & withPage 2
               & withSort SortBySeeders
               & withOrder Desc
               & withCategory 1 2
results <- search NyaaSi params

let params = defaultSearchParams "kasane teto" & withUser "hatsune miku"
results <- search NyaaSi params
```

### Recent Uploads

```haskell
-- all recent
uploads <- lastUploads NyaaSi Nothing

-- last 20
uploads <- lastUploads NyaaSi (Just 20)
```

### Torrent Information

```haskell
detail <- getTorrent NyaaSi 12345
```

### User Uploads

```haskell
-- all uploads
torrents <- getFromUser NyaaSi "bob1" Nothing

-- limit 69
torrents <- getFromUser NyaaSi "bob2" (Just 69)
```

## Categories

`withCategory cat sub`: category (`cat :: Int`) and subcategory (`sub :: Int`).
`withCategory 0 0` -> no filter

### nyaa.si

| `cat` | `sub` | Label |
|-------|-------|-------|
| 1 | 1 | Anime - Anime Music Video |
| 1 | 2 | Anime - English-translated |
| 1 | 3 | Anime - Non-English-translated |
| 1 | 4 | Anime - Raw |
| 2 | 1 | Audio - Lossless |
| 2 | 2 | Audio - Lossy |
| 3 | 1 | Literature - English-translated |
| 3 | 2 | Literature - Non-English-translated |
| 3 | 3 | Literature - Raw |
| 4 | 1 | Live Action - English-translated |
| 4 | 2 | Live Action - Idol/Promotional Video |
| 4 | 3 | Live Action - Non-English-translated |
| 4 | 4 | Live Action - Raw |
| 5 | 1 | Pictures - Graphics |
| 5 | 2 | Pictures - Photos |
| 6 | 1 | Software - Applications |
| 6 | 2 | Software - Games |

### sukebei.nyaa.si

| `cat` | `sub` | Label |
|-------|-------|-------|
| 1 | 1 | Art - Anime |
| 1 | 2 | Art - Doujinshi |
| 1 | 3 | Art - Games |
| 1 | 4 | Art - Manga |
| 1 | 5 | Art - Pictures |
| 2 | 1 | Real Life - Photobooks & Pictures |
| 2 | 2 | Real Life - Videos |

## License

MIT
