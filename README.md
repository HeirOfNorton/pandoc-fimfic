pandoc-fimfic
=============

Custom Writer for Pandoc that writes FimFiction.net compatible bbcode.

This script requires Pandoc, a program for converting documents between
several different formats, created by John MacFarlane. Find it at
<http://johnmacfarlane.net/pandoc/index.html>. Please see the Pandoc User's Guide at the
same page for details and options for using Pandoc that are not
covered in this Readme.

Usage
-----

Use this script like any other output format for Pandoc, eg:

    pandoc -t path/to/fimfic.lua mystory.md -o mystory.bbcode

The output text can then be copied and pasted into the story edit
box on FimFiction, usually unchanged.

Compatibility
-------------

This listing will focus on Markdown, HTML, and MS Word DOCX input
formats, as I believe these will be the most commonly used.

### What Works ###

*   **Paragraphs**: These may be entered as normal for each input
    format (Double spacing for Markdown, \<p> tags for HTML, etc.)
    and will be output correctly. See the next section for how
    to change the paragraph formatting in the output.

*   **Basic Formating**: Bold, italic, underlines, and strike-throughs
    work and are output correctly. Links and Images (linked from an
    external website) should work as well.

*   **Basic Styles**: Block quotes are output correctly. FimFiction
    does not have proper Headings, but sensible equivalent formatting
    will be used, and the formatting can be customized.

    Use Styles in MS Word. Ie. Use the drop-down menu of styles to choose
    the type of paragraph (Normal, Block Quote, Heading, etc.). This
    should work and be converted if possible. Never apply paragraph
    formatting directly, as this will _not_ be converted.

*   **Footnotes**: Footnotes will be gathered together and inserted at
    end of the document, separated from the story by a section break
    (by default a horizontal rule).

*   **BBCode**: When all else fails, you can use bbcode directly in
    your document. Pandoc will pass any bbcode found through without
    changing it, while still converting whatever it can.


### What Kind of Works ###

*   **Lists & Tables**: Bullet, Number, and Definition lists are output as
    plain-text versions of the lists. FimFiction does not currently
    support lists in its bbcode, so this is the best I can do.
    This is also true of tables.

*   **Small Caps, Colored text, Size**: This is due to a limitation of
    Pandoc. Pandoc, generally, does not have markup for (or recognize)
    small caps, colored text, or text with a size. As one exception,
    text enclosed in `<span>` tags with an appripriate `style` attribute
    set will be converted. Eg:
    
        <span style="text-size: large;">Big Text</span>

    This uses the standard CSS keywords for these features:
    `font-variant: small-caps;`,
    `text-size: 1.5em;`,
    `color: #F2F260;`

    Unfortunately, this only works in HTML (or in Markdown, which allows
    arbitrary HTML to be entered). Changing the color or size of text
    in MS Word does _not_ work. Again, though, simply entering the
    appropriate BBCode directly does work in all major formats.

### What Does Not Work ###

*   **Direct Formating**: Directly applying paragraph formatting in
    MS Word does not work, and likely never will. Most character
    formatting (eg. changed fonts, size and color, drop shadow) does
    not work either.

*   **Centered Text**: Centering a paragraph does not transfer, as Pandoc
    itself does not recognize centered text. The only way to get centered
    text is to use a customized Heading (see next section) or use the
    `[center]` BBCode tags directly.

Customization
-------------

Because FimFiction allows some variation in style, and different authors
like to use different styles, this script has a few options for
customization of the output. It has options for changing the formatting
of normal paragraphs, the BBCode used for Headings, the appearance of
section breaks.

All of these options are changed using the Metadata for the document.
If the input file is in Markdown format, this can be included as a
YAML Metadata block within the document itself. For _all_ formats,
the Metadata can be specified using the Pandoc option
`-M KEY=VALUE` or `--metadata=KEY:VALUE`.

All of the options have a `fimfic-` prefix to avoid clashing with any
other Metadata used in the document.

#### fimfic-single-space ####

By default paragraphs are formatted with a blank space in between them,
so they will be double-spaced when published. If you prefer single-spaced
paragraphs, include this option and give it any non-nil value, eg.
`fimfic-single-space: True`. This will remove the extra spaces between
paragraphs. This will still include double spaces around Heading and
section breaks, for clarity.

#### fimfic-no-indent ####

By default paragraphs are formatted with an indent, as this is the most
common formatting currently seen on FimFiction. If you prefer paragraphs
with no indent, include this option with any non-nil value and paragraphs
will not be automatically indented.

#### fimfic-header-1 to fimfic-header-6 ####

FimFiction does not have BBCode especially for Headers, so in order to
create headers they must be formatted directly using relevant BBCode
tags. Each of these options expects a List of two (2) Strings, which will
be output before and after the text of the Heading.

For example, if we define `fimfic-header-2` like this:

    fimfic-header-2:
      - [size=large][center]
      - [/center][/size]

and in the document we have this Heading (Markdown format):

    Part Two: Twilight's Diary
    --------------------------

then it will be written in the final document like this:

    [size=large][center]Part Two: Twilight's Diary[/center][/size]

Remember that each definition expects a list of 2 items, to go before
and after the Header text. It is an error not to have both items.
If you wish to only use one, have an empty string `""` for the other.
The lists can also but written in between brackets, like in JSON:
`fimfiction-header-5: ["[b]" , "[/b]"]`

The default definitions of these Headers is below.

    fimfic-header-1: ["[center][size=xlarge]", "[/size][/center]"]
    fimfic-header-2: ["[center][size-large]", "[/size][/center]"]
    fimfic-headar-3: ["[center][b]", "[/b][/center]"]
    fimfic-header-4: ["[b]", "[/b]"]
    fimfic-header-5: ["[i]", "[/i]"]
    fimfic-header-6: ["", ""]

#### fimfic-section-break ####

This option allows you to customize the way section breaks are
formatted in the output. By default, this script simply uses
the standard `[hr]` tag. To change this, define this option as
any string. This string will be used instead, eg.

    fimfic-section-break: [center]* * * * *[/center]

Remember that the contents of this string will be interpreted as
Markdown, so you will need to escape some characters with backslash
(` \\ `) if you do not want them to be converted.


