# gfm.md - GitHub Flavored Markdown

Reminder to self: GFM adds ~~strikethru~~, magic gh linking (repos, files,
orgs/users, issues), minor table updates, and task lists.

## Format All The Things :bangbang:

*Italic* can be `*` or `_` _surrounded_, and **bold** is double **surrounded**.
_You **can** combine them_. This is a single para even with a single hard
return in between three lines.  Only some Markdown ~~strikesthru~~.

Full blank line above makes new para.  Markdown code can be escaped 
with the obvious `\` backslash, like: this \*escapes markdown syntax\* and \|our-old-project\|.

[GH magically links](bootstrap3.html) with relative files within a repo, cross-branch sometimes.
User alerting is both @ShaneCurcuru - me on local repos; @apache/ShaneCurcuru - me in the org.

> There's never enough time to do all the nothing you want. `>blockquote` on one line -- Calvin 

> You know what we need, Hobbes? We need an attitude. Yeah, you can't 
be cool if you don't have an attitude.	`>blockquote` on first line only -- Calvin

> Sometimes I think the surest sign that intelligent life exists 
> elsewhere in the universe is that none of it has tried to 
> contact us. `>blockquote` on three lines each -- Calvin

![The Lovely Octdrey Catburn](https://octodex.github.com/images/octdrey-catburn.jpg)
> Octdrey Catburn picture

## EmojiTable

| :Left-aligned | :Center-aligned: | Right-aligned: :cat2: |
| :---         |     :---:      |          ---: |
| :white_medium_square:   | :heavy_check_mark:     | :cake:    |
| :black_large_square:     | :ballot_box_with_check:      | :mag:      |

# GFM TaskList

Changes behavior in files vs. comments/pulls.

- [x] This is a checked item in the source
- [ ] This is an incomplete item
- [ ] If we wanted more leisure, we'd invent machines that do things less efficiently.
- [ ] "That's the problem with science. You've got a bunch of empiricists trying to describe things of unimaginable wonder." -Calvin 

## Source code

```javascript
if (isECMAScript){
  return true
}
```

      if indent == spaces(4)
        then indented the code block shall be
      end


## Markdown writing help

- Markdown
  - Original Daring:boom: spec:

1. GitHub Flavored Markdown https://daringfireball.net/projects/markdown/
  1. GitHub Pages https://pages.github.com/
  1. Spec for GFM :new: https://github.github.com/gfm/
  1. End user help for GFM https://help.github.com/categories/writing-on-github/
  1. Jekyll Markdown https://jekyllrb.com/docs/posts/

* "All this modern technology just makes people try to do everything at once." <small>-Hobbes</small> 

