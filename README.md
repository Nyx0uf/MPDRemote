** MPDRemote is no longer maintained, go to https://github.com/Nyx0uf/shinobu instead**

MPDRemote
==============

[![Twitter: @Nyx0uf](https://img.shields.io/badge/contact-@Nyx0uf-blue.svg?style=flat)](https://twitter.com/Nyx0uf) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Nyx0uf/MPDRemote/blob/master/LICENSE.md) [![Swift Version](https://img.shields.io/badge/Swift-4.0-orange.svg)]() [![Build Status](https://travis-ci.org/Nyx0uf/MPDRemote.svg?branch=master)](https://travis-ci.org/Nyx0uf/MPDRemote)

![screenshot1](https://mpdremote.whine.fr/img/demo-screen-2.gif)

**MPDRemote** is an iOS application to control a [MPD](http://www.musicpd.org/) server. It is written in Swift 4 and requires at least iOS 10.

|         | FEATURES |
| --------- | --------- |
| 🗄 | Browse by albums, artists, albums artists, genres, playlists |
| 🔎 | Fuzzy search for albums, albums artists, artists, genres |
| ⏪ ⏯ ⏩ | Play, pause, next, previous |
| 🔀 🔁 | Shuffle & repeat |
| 🔈 | Volume control |
| 📍 | Track position control |
| ➕ | Add album, artist, genre, playlist to current play queue |
| 🎵 | Playlist management
| 💬 | VoiceOver compliant |
| 🌐 | Automatically find MPD server with Bonjour/Zeroconf |
| 🔊 | Audio output selection |
| 🇬🇧 🇫🇷 | English and French localized |


|         | TODO |
| ---------|--------- |
| 📱 | iPad version |
| 📺 | Apple TV version |

There is no persistence layer apart from cover caching.

LICENSES
-----------------

The MPD static library included is built from [libmpdclient](https://github.com/cmende/libmpdclient) and is released under the revised BSD License.

**MPDRemote** itself is released under the MIT License, see LICENSE.md file.
