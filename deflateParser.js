(function(){
	var distanceCode = function(code) {
		//returns { base: baseLength, extra: nrExtraBits }
		if (code < 257) {
			throw new Error("Invalid Length Code");
		} else if (code < 265) {
			return { base: code - 254, extra: 0};
		} else if (code < 269) {
		}
	};


	var parseDeflate = function(b) {
		var output = new OutputBuffer();
		var lastBlock = false;
		while (!lastBlock) {
			lastBlock = b.readBit();
			var blockType = (b.readBit() << 1) | b.readBit();
			if (blockType == 0) {
				nonCompressed(b, output);
			} else if (blockType == 3) {
				throw new Error("Invalid or Unsupported Block Type");
			} else {
				var hlit, hdist;
				if (blockType == 1) {
					hlit = Huffman.defaultHLIT;
					hdist = Huffman.defaultHDIST;
				} else {
					//unimplemented
				}
				var code = -1;
				var bit;
				while (code != 256) {
					var node = hlit;
					code = 0;
					while (!node.leaf) {
						bit = b.readBit();
						code = (code << 1) | bit;
					}
				}
			}
		}
	};
})();