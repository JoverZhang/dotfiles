import os
from fontTools.ttLib import TTFont


def find_fonts(directory, code_point):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith((".ttf", ".otf")):
                font_path = os.path.join(root, file)
                try:
                    font = TTFont(font_path)
                    for table in font['cmap'].tables:
                        if code_point in table.cmap:
                            print(f"font file: {font_path}")
                            break
                except:
                    continue


char = input("char: ")
code_point = ord(char)

find_fonts("/usr/share/fonts/", code_point)
find_fonts(os.path.expandvars("$HOME/.local/share/fonts/"), code_point)
