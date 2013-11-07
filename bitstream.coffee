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
		undefined

	writeBuffer: (data)->
		if @buffer.length == 0
			@buffer = data
		else
			@buffer = @buffer.concat(data)
		undefined

	writeByte: (byte)->
		@buffer.push(byte)

module.exports = {BitStream}