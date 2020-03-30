# CSS Selectors - Shane Style

## References Worth Reading

- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors

## Select Some CSS

```css

#id,
.class,
elementname,
[attrpresent],
[attr = val] {
  background-color: #265a88;
}

```

**Grouping** All, elems, commas

**Combinators**

- Descendant **space** `table td`
- Child **>** `tbody > tr`
- General sibling **~** `p ~ span` (all of them)
- Adjacent sibling **+** `h2 + p` (immediate sibling only)
- Column combinator **||** example: col || td will match all <td> elements that belong to the scope of the <col>

**Pseudo Classes**

`a:visited` Single colon are state variables from browser.
`p::first-line` Double colon are inferable from HTML DOM logically.
