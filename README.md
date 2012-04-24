iPhoto To SQL
=============

iPhoto To SQL is an export plugin for iPhoto that will create an SQL dump file with all picture metadata in addition to creating scaled images and thumbnails. If you've written your own photo gallery software, use this to get your photos and associated metadeta into your database backend. In addition it can generate web safe file names based upon the image's title in iPhoto.

iPhoto To SQL will create the following fields: title, comment, keywords, stars, date, album, thumbnail filename and image filename. You can set height/width maximums on the thumbnails and images and they will be rescaled with their aspect ratio preserved.

Installation
-----

Single user installation, put into: `~/Library/Application Support/iPhoto/Plugins`.
System-wide installation, put into: `/Library/Application Support/iPhoto/Plugins`.

Usage
-----

Run iPhoto and select, iPhoto -> Export. Select the SQL tab and select your options.
