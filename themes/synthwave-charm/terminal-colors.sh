# Synthwave Everything — ANSI palette for non-Ghostty terminals (SSH, etc.)
# Sets the terminal's base 16 colors + background/foreground via OSC sequences
# so the theme looks correct even without Ghostty providing the palette.
#
# Sourced by .zshrc when TERM_PROGRAM != ghostty.

# Background & foreground
printf '\033]11;#2a2139\033\\'
printf '\033]10;#f0eff1\033\\'

# Cursor
printf '\033]12;#72f1b8\033\\'

# ANSI palette (0–15)
printf '\033]4;0;#fefefe\033\\'
printf '\033]4;1;#f97e72\033\\'
printf '\033]4;2;#72f1b8\033\\'
printf '\033]4;3;#fede5d\033\\'
printf '\033]4;4;#6d77b3\033\\'
printf '\033]4;5;#c792ea\033\\'
printf '\033]4;6;#f772e0\033\\'
printf '\033]4;7;#fefefe\033\\'
printf '\033]4;8;#fefefe\033\\'
printf '\033]4;9;#f88414\033\\'
printf '\033]4;10;#72f1b8\033\\'
printf '\033]4;11;#fff951\033\\'
printf '\033]4;12;#36f9f6\033\\'
printf '\033]4;13;#e1acff\033\\'
printf '\033]4;14;#f92aad\033\\'
printf '\033]4;15;#fefefe\033\\'
