#!/bin/sh
# Checks the site: en/ru mirror, relative links, lang/title/h1, CSP + no-referrer, language links.
# Usage: sh tools/check.sh   (prints problems, exits 1 if there are any)
# shortcut: attributes are found per tag after splitting on '<', so a tag must
# stay on one line; switch to a real HTML parser if pages ever break that.

cd "$(dirname "$0")/.." || exit 1

pages() {
    find . -name '*.html'
}

# attr NAME FILE: every value of NAME="..." in FILE, one per line
attr() {
    tr '<' '\n' < "$2" | sed -n "s/.* $1=\"\([^\"]*\)\".*/\1/p"
}

# canon PATH: absolute path with . and .. resolved (the file itself must exist)
canon() {
    d=$(cd "${1%/*}" 2>/dev/null && pwd) && printf '%s/%s\n' "$d" "${1##*/}"
}

check() {
    # 1. en/ and ru/ have the same files
    for a in en ru; do
        if [ "$a" = en ]; then b=ru; else b=en; fi
        find "$a" -type f | while IFS= read -r f; do
            [ -e "$b/${f#*/}" ] || echo "$f: missing $b/${f#*/}"
        done
    done

    pages | while IFS= read -r f; do
        dir=${f%/*}

        # 2. every relative href/src points to an existing file
        { attr href "$f"; attr src "$f"; } | while IFS= read -r u; do
            case $u in
                http://* | https://* | mailto:* | '#'*) continue ;;
            esac
            p=${u%%#*}
            case $p in
                /*)
                    # only 404.html may use root paths (Codeberg serves it for any path)
                    if [ "$f" != ./404.html ]; then echo "$f: root path $u"; continue; fi
                    t=.$p ;;
                *) t=$dir/$p ;;
            esac
            case $t in */) t=${t}index.html ;; esac
            [ -e "$t" ] || echo "$f: broken link $u"
        done

        # 3. lang, title, exactly one h1
        grep -q '<html lang="[a-z][a-z]*"' "$f" || echo "$f: no lang"
        grep -q '<title>[^<]' "$f" || echo "$f: no title"
        # the browser must block scripts and third-party loads, and send no referrer
        grep -q "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'self'; script-src 'none';" "$f" || echo "$f: no CSP"
        grep -q '<meta name="referrer" content="no-referrer">' "$f" || echo "$f: no no-referrer"
        n=$(tr '<' '\n' < "$f" | grep -c '^h1[ >]')
        [ "$n" -eq 1 ] || echo "$f: $n h1"

        # 4. on en/ru pages: both hreflang alternates, and every hreflang link
        #    leads to the same page in that language
        case $f in ./en/* | ./ru/*) ;; *) continue ;; esac
        rest=${f#./*/}
        for l in en ru; do
            grep -q "<link rel=\"alternate\" hreflang=\"$l\"" "$f" || echo "$f: no hreflang $l alternate"
        done
        tr '<' '\n' < "$f" | grep ' hreflang="' | while IFS= read -r tag; do
            l=$(printf '%s\n' "$tag" | sed 's/.* hreflang="\([^"]*\)".*/\1/')
            h=$(printf '%s\n' "$tag" | sed -n 's/.* href="\([^"]*\)".*/\1/p')
            [ "$(canon "$dir/$h")" = "$PWD/$l/$rest" ] ||
                echo "$f: hreflang $l link $h is not $l/$rest"
        done
    done

    # titles are unique
    pages | while IFS= read -r f; do
        sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' "$f"
    done | sort | uniq -d | sed 's/^/duplicate title: /'
}

errors=$(check)
if [ -n "$errors" ]; then
    printf '%s\n' "$errors"
    exit 1
fi
echo "ok: $(pages | wc -l | tr -d ' ') pages"
