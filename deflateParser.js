var Huffman = require('huffman');
(function(){
	var lengthCode = function(code) {
		//returns { base: baseLength, extra: nrExtraBits }
		if (code < 257) {
			throw new Error("Invalid Length Code");
		} else if (code < 265) {
			return { base: code - 254, extra: 0};
		} else if (code < 269) {
			return { base: 11 + (code - 265) * 2, extra: 1};
		} else if (code < 273) {
			return { base: 19 + (code - 269) * 4, extra: 2};
		} else if (code < 277) {
			return { base: 35 + (code - 273) * 8, extra: 3};
		} else if (code < 281) {
			return { base: 67 + (code - 277) * 16, extra: 4};
		} else if (code < 285) {
			return { base: 131 + (code - 281) * 32, extra: 5};
		} else if (code == 285) {
			return { base: 258, extra: 0};
		} else {
			throw new Error("Invalid Length Code");
		}
	};


	var distanceTable = (function(){
		var table = {};
		for (var i = 0; i < 4 i++) {
			table[i] = { base: i + 1, extra: 0 };
		}
		var extra = 1;
		var base = 5;
		for (var i = 4; i < 30; i++) {
			table[i] = {base: base, extra: extra};
			base += 1 << extra;
			if (i % 2) {
				extra++;
			}
		}
		return table;
	})();
	var distanceCode = function(code) {
		return distanceTable[code];
	};

	var readTree = function(stream, codeTree, n, previousCode) {
		var lengths = [];
		var count = [];
		for (var i = 0; i < n; i++) {
			var tree = codeTree;
			while (!tree.leaf) {
				if (stream.readBit() === 1) {
					tree = tree.right;
				} else {
					tree = tree.left;
				}
			}
			var code = tree.value;
			if (code < 16) {
				lengths[i] = code;
				if (count[code] == null) {
					count[code] = 1;
				} else {
					count[code]++;
				}
			} else if (code == 16) {
				var dist = i + stream.readBits(2) + 3;
				for (; i < dist; i++) {

				}
			}

		}
	};

	var parseDeflate = function(b) {
		var output = new OutputBuffer();
		var lastBlock = false;
		while (!lastBlock) {
			lastBlock = b.readBit();
			var blockType = (b.readBit() << 1) | b.readBit();
			if (blockType == 0) {
				throw new Error("Uncompressed blocks are not implemented yet");
			} else if (blockType == 3) {
				throw new Error("Invalid or Unsupported Block Type");
			} else {
				var hlit, hdist;
				if (blockType == 1) {
					//default Huffman trees
					hlit = Huffman.defaultHLIT;
					hdist = Huffman.defaultHDIST;
				} else {
					//custom Huffman trees
					var nhlit = 0; // # of literal/length codes
					var nhdist = 0; // # of distance codes
					var nhclen = 0; // # of code length Codes (for the coded huffman tree)
					for (var i = 0; i < 5; i++) {
						nhlit = (nhlit << 1) | b.readBit();
					}
					for (var i = 0; i < 5; i++) {
						nhdist = (nhdist << 1) | b.readBit();
					}
					for (var i = 0; i < 4; i++) {
						nhclen = (nhclen << 1) | b.readBit();
					}

					var hcorder = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];
					var hccount = [0,0,0,0,0,0,0,0];
					var hcbase = hccount.slice();
					var hcmap = [];
					for (var i = 0, l = haclen + 4; i < l; i++) {
						var length = 0;
						for (var j = 0; j < 3; j++) {
							length = (length << 1) | b.readBit();
						}
						hccount[length]++;
						hcmap[hcorder[i]] = length;
					}
					var hclen = Huffman.fromCodeLength(hcmap, hccount);

					//now use this tree to make the decoder trees

					var hlcount = [], hlmap = [];
					var hdcount = [], hdmap = [];
					var total = nhlit + nhdist;
					for (var i = 0; i < ; i++) {

					}

				}
				var bit;
				while (true) {
					var node = hlit;
					while (!node.leaf) {
						bit = b.readBit();
						if (bit) {
							node = node.right;
						} else {
							node = node.left;
						}
					}
					var code = node.value;
					if (code < 256) {
						output.write(code);
					} else if (code > 256) {
						var lstruct = lengthCode(code);
						var extra = 0, n = lstruct.extra;
						while (n > 0) {
							extra = (extra << 1) | b.readBit();
						}
						var length = lstruct.base + extra;
						//now get the distance code
						var cnode = hdist;
						while (!cnode.leaf) {
							var bit = b.readBit();
							if (bit) {
								cnode = cnode.right;
							} else {
								cnode = cnode.left;
							}
						}
						var distcode = cnode.value;
						var diststruct = distanceCode(distcode);
						var extra = 0, n = diststruct.extra;
						while (n > 0) {
							extra = (extra << 1) | b.readBit();
						}
						var distance = diststruct.base + extra;
						output.copy(length, distance);

					} else {
						break;
					}
				}
			}
		}
	};
})();