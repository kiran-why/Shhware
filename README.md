# Shhware site

Static site for Shhware, hosted on Codeberg Pages. Plain HTML5 and one `style.css`.

## Structure

```
index.html        English home at the root (copy of en/index.html, keep in sync)
404.html          error page (Codeberg serves it for any missing path)
style.css
en/ ru/           two mirrored trees, same file names
  index.html  philosophy.html  news.html  contacts.html
  projects/index.html
  projects/shh-dotfiles/   wiki: index install shh components desktop keybinds layout known-issues
tools/check.sh    site check (not part of the site)
```

## Rules

- No JavaScript, no generators, no build step, no external resources.
- All links are relative. Only `404.html` uses root paths (`/en/`, `/style.css`):
  it works only when the site is at the domain root.
- Every page exists in `en/` and `ru/`. The language switch (`English · Russian`,
  top right) links to the same page in the other language.
- Each page: `lang`, a unique `<title>`, exactly one `<h1>`, headings in order.
  It must read well in `lynx` / `w3m`.
- Keep every tag on one line: `tools/check.sh` reads attributes per tag.

## Adding a page

1. Copy a neighbouring page in `en/` and the same page in `ru/`, under the same name.
2. Change `<title>`, `<h1>`, the content and the relative paths if the folder depth differs.
3. Add it to the site tree (`<nav class="tree">`, after `<main>`) on every page,
   and to the back / next links of its wiki neighbours. A new project is a
   `<details>` folder in the tree (copy the shh-dotfiles one); add `open` only on
   that project's own pages.
4. Run `sh tools/check.sh`. It must print `ok`.
