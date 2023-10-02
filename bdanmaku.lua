-- Author: UlyssesZhan <gmail.com>
-- License: MIT
-- Homepage: https://github.com/UlyssesZh/bdanmaku

local CURL = mp.get_opt('curl_executable') or 'curl'
local BILIASS = mp.get_opt('biliass_executable') or 'biliass'
local BILIASS_OPTS = {}
for token in (mp.get_opt('biliass_options') or ''):gmatch('[^%s]+') do
	BILIASS_OPTS[#BILIASS_OPTS + 1] = token
end
local utils = require 'mp.utils'

local danmaku_changed = false
local xml_filename = nil
local danmaku_applied = false

function on_sub_change(name, data)
	local url = mp.get_property(name)
	if not url or danmaku_changed then
		return
	end
	danmaku_changed = true

	mp.msg.debug('sub file changed, checking whether it is XML danmaku')
	url = url:match '%w+://comment.bilibili.com/.*%.xml$'
	if not url then
		mp.msg.debug('not a valid Bilibili XML danmaku URL, skipping')
		return
	end

	xml_filename = '/tmp/'..os.time()..'.danmaku.xml'
	local curl_args = {
		CURL, url,
		'--silent',
		'--output', xml_filename,
		'--compressed'
	}
	mp.msg.debug('curl_command: '..table.concat(curl_args, ' '))
	local curl_result = utils.subprocess({args = curl_args})
	if not curl_result.status == 0 then
		mp.msg.warn('downloading XML danmaku from '..url..' failed: '..curl_result.error)
		xml_filename = nil
		return
	end
	mp.msg.debug('danmaku downloaded, will convert to ASS after OSD init')

end

function on_osd_change(name, data)
	local width, height, par = mp.get_osd_size()
	if width == 0 or height == 0 or danmaku_applied or not xml_filename then
		return
	end
	danmaku_applied = true

	mp.msg.debug('OSD initialized, convert XML danmaku to ASS now')
	local resolution = width..'x'..height
	local ass_filename = '/tmp/'..os.time()..'.danmaku.ass'
	local biliass_args = {
		BILIASS, xml_filename,
		'--size', resolution,
		'--output', ass_filename,
		table.unpack(BILIASS_OPTS)
	}
	mp.msg.debug('biliass_command: '..table.concat(biliass_args, ' '))
	local biliass_result = utils.subprocess({args = biliass_args})
	if not biliass_result.status == 0 then
		mp.msg.warn('converting XML danmaku from '..xml_filename..' to '..ass_filename..' failed: '..biliass_result.error)
		return
	end

	local sid = mp.get_property('track-list/0/id')
	mp.msg.debug('deleting original subtitle sid='..sid)
	mp.commandv('sub-remove', sid)
	mp.msg.debug('adding new subtitle')
	mp.commandv('sub-add', ass_filename, 'select', 'danmaku', 'danmaku')
end

mp.observe_property('track-list/0/external-filename', nil, on_sub_change)
mp.observe_property('osd-width', nil, on_osd_change)
mp.observe_property('osd-height', nil, on_osd_change)
