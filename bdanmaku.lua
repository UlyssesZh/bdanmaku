-- Author: UlyssesZhan <ulysseszhan@gmail.com>
-- License: MIT
-- Homepage: https://github.com/UlyssesZh/bdanmaku

table.unpack = table.unpack or unpack -- 5.1 compatibility
local CURL = mp.get_opt('curl_executable') or 'curl'
local BILIASS = mp.get_opt('biliass_executable') or 'biliass'
local TMPDIR = mp.get_opt('tmpdir') or '/tmp/danmaku'
local BILIASS_OPTS = {}
for token in (mp.get_opt('biliass_options') or '--fontsize 48 --alpha 0.5 --duration-marquee 10'):gmatch('[^%s]+') do
	BILIASS_OPTS[#BILIASS_OPTS + 1] = token
end
local utils = require 'mp.utils'

local danmaku_track_id = nil
local xml_filename = nil

function download_xml()
	local url = nil
	for track_i = 0, mp.get_property('track-list/count') - 1 do
		url = mp.get_property('track-list/'..track_i..'/external-filename')
		if url then
			url = url:match '%w+://comment.bilibili.com/.*%.xml$'
			if url then
				danmaku_track_id = track_i
				break
			end
		end
	end
	if not danmaku_track_id then
		mp.msg.debug('no XML danmaku found')
		return
	end
	if os.execute('mkdir -p '..TMPDIR) ~= 0 then
		os.execute('powershell mkdir '..TMPDIR)
	end
	xml_filename = TMPDIR..'/'..mp.get_property('pid')..'.xml'
	local curl_args = {
		CURL, url,
		'--silent',
		'--output', xml_filename,
		'--compressed'
	}
	mp.msg.debug('curl_command: '..table.concat(curl_args, ' '))
	local curl_result = utils.subprocess({args = curl_args})
	if curl_result.status == 0 then
		mp.msg.debug('danmaku downloaded, will convert to ASS')
	else
		xml_filename = nil
		mp.msg.warn('downloading XML danmaku from '..url..' failed: '..curl_result.error)
	end
end

function replace_sub()
	local width, height, par = mp.get_osd_size()
	if width == 0 or height == 0 or not xml_filename then
		return
	end
	local resolution = width..'x'..height
	local ass_filename = TMPDIR..'/'..mp.get_property('pid')..'.ass'
	local biliass_args = {
		BILIASS, xml_filename,
		'--size', resolution,
		'--output', ass_filename,
		table.unpack(BILIASS_OPTS)
	}
	mp.msg.debug('biliass_command: '..table.concat(biliass_args, ' '))
	local biliass_result = utils.subprocess({args = biliass_args})
	if biliass_result.status == 0 then
		local sid = mp.get_property('track-list/'..danmaku_track_id..'/id')
		mp.msg.debug('deleting original subtitle sid='..sid)
		mp.commandv('sub-remove', sid)
		mp.msg.debug('adding new subtitle')
		mp.commandv('sub-add', ass_filename, 'select', 'danmaku', 'danmaku')
		for track_i = 0, mp.get_property('track-list/count') - 1 do
			if mp.get_property('track-list/'..track_i..'/external-filename') == ass_filename then
				danmaku_track_id = track_i
				break
			end
		end
	else
		mp.msg.warn('converting XML danmaku from '..xml_filename..' to '..ass_filename..' failed: '..biliass_result.error)
	end
end

function shutdown_handler()
	os.remove(TMPDIR..'/'..mp.get_property('pid')..'.xml')
	os.remove(TMPDIR..'/'..mp.get_property('pid')..'.ass')
end

mp.register_event('file-loaded', download_xml)
mp.observe_property('osd-width', nil, replace_sub)
mp.observe_property('osd-height', nil, replace_sub)
mp.register_event("shutdown", shutdown_handler)
