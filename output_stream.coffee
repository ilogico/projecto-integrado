"use strict"

class OutputStream
	constructor: ->
		@buff = []
		@partialLength = 0
		@partial = 0

	writeBit: (bit)->
		@partial = @partial | (bit << @partialLength)
		@partialLength++
		if @partialLength == 8
			@buff.push @partial
			@partialLength = @partial = 0
		true

	writeBits: (values, length)->
		length--
		while length >= 0
			@writeBit((values >> length) & 1)
			length--
		true

	getBuffer: ->
		size = @buff.length + if @partialLength then 1 else 0
		r = new Uint8Array(size)
		for b, i in @buff
			r[i] = @buff[i]
		if @partialLength
			r[size - 1] = @partial
		r

module.exports = OutputStream