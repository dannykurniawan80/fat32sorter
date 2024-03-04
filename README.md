# FAT32 Sorter

I know that there already some project out there that has the same functionality. Unfortunately, most of them either command-line based, has a very simple UI, and there are not much feature that I need, for example: sort based on modified date instead of file name, also no built-in feature for renaming files.

So, long story short, I ended up building my own FAT32 Sorter which suit my need.

# Why Sort?

This tool is meant to sort files (and folders) in FAT32 storage media.

Why bother to sort? The reason is because there are still devices out there that reads FAT32 storage like SD Cards or Flash Drives with very limited CPU power, that when they read the content of the storage, they read it as what they would appear in the FAT32 formatted storage entries.

Most commonly found devices are car stereos, which some of the old ones or some of them that doesn't have fancy firmware like Android one, will play MP3 files "somewhat" randomly from the storage.

While when you are seeing the files using computer or laptop seems to be in some order, the sorting in computer or laptop is done by the Operating System of your laptop that will make them display the files in particular order to your liking. But the order of the file entries in FAT32 filesystem doesn't need to be in that way. In fact, most of the time the file entries is somewhat seems random (well, not exactly random, this is due to the way Operating Systems do add/remove/rename files, it will move the entries around to fit available space). And Operating System doesn't provide any means to change the order by the user.

In fact some of you might have experience on how you need to copy your MP3 files in the order of how you want them to appear in your car stereo to a blank (or newly formatted) FAT32 filesystem.

Another use of this tool for me is with my 3D printer firmware. Since the firmware will only read in the order how files appear in FAT32 entries, sometimes my file buried among my older files which makes me hard to find the new file to print.

# Features
- Files and folders sorting using preset sort orders, or you can even customize your own sorting orders using Advanced Sort feature.
- Not just sort using file name, you can also sort using **Creation Date**, **Modified Date**, or **File Size**, both Ascending or Descending.
- ID3 fields support for MP3 files (currently supports **Track**, **Disc**, **Title**, **Artist**, **Album**, and **Year** fields), so you can also sort your MP3 files according to the ID3 metadata instead of just on relying to the file name.
- Rename feature that can easily add and remove number prefixes based on either entry position, or Track and Disc for MP3 files.
- Arbitrary ordering! Yes, you can reorder files or folders the way you like using drag and drop. It even supports multiple selection! You're not tied to sort your files and folders using specific properties. Once you're good with the order, just write the changes to the storage.

# How does it work?

If you want to know more details on how FAT32 store its files, then [this](https://www.codeproject.com/Articles/95721/FAT-32-Sorter-Utility-that-Sorts-the-Files-Table-i) article might gives you a much better understanding how it works.

But for some of you that just want to know at a glance, basically in any storage, your file is actually stored in 2 parts, the first part is the content of the file data itself. The second one is the entry where to locate the data.

You can pretty much assume that any storage would look like a book with Table Of Contents pages. Your data will be somewhere buried among those thick pages. To locate it any Operating System will need to see the Table Of Content, locate your file name, then lookup the page number where your data being stored.

The Table Of Contents itself doesn't required to be sorted in particular order, the Operating System will sort it out to display it to you sorted to your liking. Changing sort order in Windows Explorer or Mac's Finder will not change the order of this Table Of Contents.

FAT32 Sorter is a utility to re-arrange the entries inside the filesystem's "table of contents" to be in the order that you define. This will make low-end devices that reads those storage to read them in the same order that you put.

In short, to make your car stereo reads your MP3 files in the order you want them to be, easily!

# Notes

- Some car stereo might do partial sorting to the files. For example, my car have Kenwood DDX4 stereo, which somewhat reads folders in the order how they would appear in the FAT32 entries, but will sort MP3 files using file names. In this case, I need to rename the files using number prefixes to make them appear the way I want them to be.
- After renaming your files, your sorting orders might changed. This is due to FAT32 Sorter uses different way to rename and to sort. Renaming will depends on the Operating System's functionality, which if Long File Name property increase in length, it might need to reallocate the Long File Name entries to the next free slots. You might need to re-sort them again after renaming.

# Developed By
- Danny Kurniawan (danny.kurniawan@gmail.com)

# License

Copyright 2024 Danny Kurniawan

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.