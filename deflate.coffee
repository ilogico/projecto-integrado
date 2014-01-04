"use strict"

args = process.argv
if args.length < 3
	console.log "no file to compress"
else
	fs = require 'fs'
	fs.readFile args[2], (e, d)->
		if e
			console.log "error opening file"
			throw e
		originalSize = d.length
		try
			encoded = require('./deflate_encoder')(d)
			compressedSize = encoded.length
			fs.writeFile args[2] + ".deflate", new Buffer(encoded), (e)->
				if e
					console.log "error writing file"
					throw e
				ratio = (compressedSize * 100 / originalSize).toFixed(2) + '%'
				console.log "Finished! Compression ratio: " + ratio
		catch error
			console.log "error compressing data:", error.toString()
			throw error

		
