# bdanmaku

[mpv](https://mpv.io) plugin to correctly display Bilibili danmaku.
Powered by [biliass](https://github.com/yutto-dev/biliass).

## Installation

First, [install biliass](https://github.com/yutto-dev/biliass#install).
Then, see [mpv documentation](https://mpv.io/manual/stable/#script-location) for how to run the script in mpv.

## Usage

First, use [yt-dlp](https://github.com/yt-dlp/yt-dlp) as the youtube-dl executable in mpv
by [setting the `ytdl_path` option](https://mpv.io/manual/stable/#options-ytdl-path).
Then, watch Bilibili video by running a command like this:

```shell
mpv https://www.bilibili.com/video/BV1Sm4y1N78J
```

## Configuration

You can configure the plugin by setting the `script-opts` option in mpv.
Set the biliass executable by setting the `biliass_executable` option like this:

```shell
mpv --script-opts=biliass_executable=/path/to/biliass https://www.bilibili.com/video/BV1Sm4y1N78J
```

You can also set the `biliass_options` option to pass additional options to biliass.
For example, if you want to make the opacity of danmaku to 0.1, you can do this:

```shell
mpv --script-opts=biliass_options=-a\ 0.1 https://www.bilibili.com/video/BV1Sm4y1N78J
```

## Notice for Windows users

You have to specify the `tmpdir` option on Windows (e.g. `--script-opts=tmpdir=C:\tmp`).
Otherwise, downloading danmaku will fail.

Because of a [bug](https://github.com/yutto-dev/biliass/issues/28) of biliass on Windows,
you may see errors about decoding danmaku files.
Install [@Mark-Joy's fork](https://github.com/Mark-Joy/biliass) instead to fix this.
