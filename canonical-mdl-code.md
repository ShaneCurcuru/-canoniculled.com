### Desktop images in Markdown Table

The problem with other people's code samples is they never work *quite* the way you want your site to work.

| coffee-698870_1280 | coffee-beans-1248394 |
| ---- | ---- |
| heart-318571_1920 | heart-1050338_1920 |
| love-1100255_1920 | pastries-756601_1920 |
| wood-850085_1920 | ginger-1287424_1920 (square) |

### Google MDL Examples

material-icons face is <i class="material-icons">face</i>,
big Face adds md-48 <i class="material-icons md-48">face</i>,
color Face is na <i class="material-icons md-48 na">face</i> face.<br/>

-i class="material-icons">alarm</i> gives <i class="material-icons">alarm</i>,
-i class="material-icons">plus_one</i> gives <i class="material-icons">plus_one</i>,
and div class="material-icons mdl-badge mdl-badge--overlap" data-badge="♥" >account_box<
<div class="material-icons mdl-badge mdl-badge--overlap" data-badge="♥">account_box</div>

-a href="#" class="mdl-badge" data-badge="7">This link contains a badge.<
<a href="#" class="mdl-badge" data-badge="7">This link contains a badge.</a>

Accent-colored raised button with ripple
<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
Button
</button>

Three Line List with secondary info and action
<style>
.demo-list-three {
width: 650px;
}
</style>

<ul class="demo-list-three mdl-list">
<li class="mdl-list__item mdl-list__item--three-line">
<span class="mdl-list__item-primary-content">
  <i class="material-icons mdl-list__item-avatar">person</i>
  <span>First Actor</span>
  <span class="mdl-list__item-text-body">
    Bryan Cranston played the role of Walter in Breaking Bad. He is also known
    for playing Hal in Malcom in the Middle.
  </span>
</span>
<span class="mdl-list__item-secondary-content">
  <a class="mdl-list__item-secondary-action" href="#"><i class="material-icons">star</i></a>
</span>
</li>
<li class="mdl-list__item mdl-list__item--three-line">
<span class="mdl-list__item-primary-content">
  <i class="material-icons  mdl-list__item-avatar">alarm</i>
  <span>Alarm Paul</span>
  <span class="mdl-list__item-text-body">
    Aaron Paul played the role of Jesse in Breaking Bad. He also featured in
    the "Need For Speed" Movie.
  </span>
</span>
<span class="mdl-list__item-secondary-content">
  <a class="mdl-list__item-secondary-action" href="#"><i class="material-icons">plus_one</i></a>
</span>
</li>
<li class="mdl-list__item mdl-list__item--three-line">
<span class="mdl-list__item-primary-content">
  <i class="material-icons  mdl-list__item-avatar">person</i>
  <span>Bob Hopendope</span>
  <span class="mdl-list__item-text-body">
    Bob Odinkrik played the role of Saul in Breaking Bad. Due to public fondness for the
    character, Bob stars in his own show now, called "Better Call Saul".
  </span>
</span>
<span class="mdl-list__item-secondary-content">
  <a class="mdl-list__item-secondary-action" href="#"><i class="material-icons">star</i></a>
</span>
</li>
</ul>

**TOAST** - notification window with button and counter
<button id="demo-show-toast" class="mdl-button mdl-js-button mdl-button--raised" type="button">Show Toast</button>
<div id="demo-toast-example" class="mdl-js-snackbar mdl-snackbar">
<div class="mdl-snackbar__text"></div>
<button class="mdl-snackbar__action" type="button"></button>
</div>
<script>
(function() {
'use strict';
window['counter'] = 0;
var snackbarContainer = document.querySelector('#demo-toast-example');
var showToastButton = document.querySelector('#demo-show-toast');
showToastButton.addEventListener('click', function() {
'use strict';
var data = {message: 'Example Message # ' + ++counter};
snackbarContainer.MaterialSnackbar.showSnackbar(data);
});
}());
</script>

Simple Tooltip (add-follow)
<div id="tt1" class="icon material-icons">add</div>
<div class="mdl-tooltip" for="tt1">
Follow
</div>

Multiline Tooltip (share-via)
<div id="tt4" class="icon material-icons">share</div>
<div class="mdl-tooltip" for="tt4">
Share your content<br>via social media
</div>

Changing the body text via mdl-typography--body-*
<p class="mdl-typography--body-1">body-1Regular 14px (Device), Regular 13px (Desktop)</p>
<p class="mdl-typography--body-1-force-preferred-font">body-1-force-preferred-font Regular 14px (Device), Regular 13px (Desktop)</p>
<p class="mdl-typography--body-2">body-2 Medium 14px (Device), Medium 13px (Desktop)</p>
<p class="mdl-typography--body-2-color-contrast">body-2-color-contrast Body with color contrast</p>
<p class="mdl-typography--body-2-force-preferred-font">body-2-force-preferred-fontMedium 14px (Device), Medium 13px (Desktop)</p>
<p class="mdl-typography--body-1">
 Here is some mdl-typography--body-1 text <span class="mdl-typography--caption-color-contrast">(with mdl-typography--caption-color-contrast)</span>
</p>
<p>
<div class="mdl-typography--headline">--Headline - Regular 24px</div>
<div class="mdl-typography--subhead">--Subhead - Regular 16px (Device), Regular 15px (Desktop)</div>
<br />
<div class="mdl-typography--button">--Button - Medium (All Caps) 14px</div>
<br />
<div class="mdl-typography--menu">--Menu - Medium 14px (Device), Medium 13px (Desktop)</div>
</p>

## Markdown-only styling H2

1. First ordered list item
2. Another item
⋅⋅* Unordered sub-list.
1. Actual numbers don't matter, just that it's a number
⋅⋅1. Ordered sub-list
4. And another item.

> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote.

### H3 Test

⋅⋅⋅You can have properly indented paragraphs within list items. Notice the blank line above, and the leading spaces (at least one, but we'll use three here to also align the raw Markdown).

⋅⋅⋅To have a line break without a paragraph, you will need to use two trailing spaces.⋅⋅
⋅⋅⋅Note that this line is separate, but within the same paragraph.⋅⋅
⋅⋅⋅(This is contrary to the typical GFM line break behaviour, where trailing spaces are not required.)

#### H4 Test

* Unordered list can use asterisks
- Or minuses
+ Or pluses

Colons can be used to align columns.

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |


##### H5 Test

[I'm an inline-style link with title](https://www.google.com "Google's Homepage")

URLs and URLs in angle brackets will automatically get turned into links.
http://www.example.com or <http://www.example.com> and sometimes
example.com (but not on Github, for example).

###### H6 Test

Thanks for reading!
