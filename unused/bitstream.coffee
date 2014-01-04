"use strict"
class BitStream
	constructor: ->
		@buffer = []
		@byte = 0
		@canRead = false
		@bitMode()

	readBit = ->
		if @bits == 8
			@byte = @buffer.shift()
			@bits = 0
		bit = @byte & 1
		@byte = @byte >> 1
		@bits++
		if @bits == 8 and @buffer.length == 0
			@canRead = false
		bit

	readByte = ->
		if @buffer.length < 2
			@canRead = false
		@buffer.shift()

	bitMode: ->
		@read = readBit
		@bits = 8
		undefined

	byteMode: ->
		@read = readByte
		@canRead = @buffer.length > 0
		return

	writeBuffer: (data)->
		@writeByte(byte) for byte in data
		return

	writeByte: (byte)->
		@buffer.push(byte)
		@canRead = true
		return

module.exports = {BitStream}