(function() {
	"use strict"
	//private functions
	var heapify, bubbleUp, bubbleDown;

	var Heap = function Heap(comp, array) {
		this.comp = comp;
		this.array = array || [];
		if (this.array.length > 0) {
			heapify(this.array, comp);
		}
	}


	bubbleDown = function(a, idx, comp) {
		var value = a[idx];
		var parent;
		while (idx > 0) {
			parent = (idx - 1) >> 1;
			if (comp(a[parent], value) > 0) {
				a[idx] = a[parent];
				idx = parent;
			} else {
				break;
			}
		}
		a[idx] = value;
	};

	bubbleUp = function(a, comp) {
		var leftChild, rightChild, child;
		var idx = 0, value = a[0], l = a.length;
		for (;;) {
			leftChild = (idx << 1) + 1;
			if (leftChild >= l) {
				break;
			}
			rightChild = leftChild + 1;
			if (rightChild >= l || comp(a[leftChild], a[rightChild]) < 0) {
				child = leftChild;
			} else {
				child = rightChild;
			}
			if (comp(a[child], value) < 0) {
				a[idx] = a[child];
				idx = child;
			} else {
				break;
			}
		}
		a[idx] = value;
	};

	heapify = function(a, comp) {
		for (var i = 0, l = a.length; i < l; i++) {
			bubbleDown(a, i, comp);
		}
	}

	Heap.prototype.push = function(value) {
		this.array.push(value);
		bubbleDown(a, a.length - 1, this.comp);
	};

	Heap.prototype.pop = function() {
		var a = this.array;
		if (a.length > 1) {
			var ret = a[0];
			a[0] = a.pop();
			bubbleUp(a, this.comp);
			return ret;
		} else {
			return a.pop();
		}
	};

	Heap.prototype.pushPop = function(value) {
		var a = this.array, c = this.comp;
		if (a.length > 0 && c(a[0], value) < 0) {
			var ret = a[0];
			a[0] = value;
			bubbleUp(a, c);
			return ret;
		} else {
			return value;
		}
	};

	Heap.prototype.size = function() {
		return this.array.length;
	};

	var HuffmanNode = function HuffmanNode() {};

	HuffmanNode.prototype.insertCode = function(code, codeSize, value) {
		var tree = this;
		var dir;
		while (codeSize-- > 1) {
			dir = (code >> codeSize) & 1 ? "right" : "left";
			if (tree[dir] == null) tree[dir] = new HuffmanNode();
			tree = tree[dir];
		}
		dir = (code >> codeSize) & 1 ? "right" : "left";
		tree[dir] = new HuffmanLeaf(value, 0);
	};

	var HuffmanLeaf = function HuffmanLeaf(value, count) {
		this.value = value;
		this.count = count;
		this.leaf = true;
	};
	HuffmanLeaf.prototype = new HuffmanNode();

	var HuffmanBranch = function HuffmanBranch(left, right) {
		this.left = left;
		this.right = right;
		this.count = left.count + right.count;
		this.leaf = false;
	};
	HuffmanBranch.prototype = new HuffmanNode();

	var huffmanComp = function(n0, n1) {
		return n0.count - n1.count;
	}

	var fromFrequencies = function(a) {
		//makes a HuffmanTree from an array of frequencies
		var h = new Heap(huffmanComp, a.map(function(v, i) {
			return new HuffmanLeaf(i, v);
		}));
		var current = h.pop();

		while (current.count == 0) {
			current = h.pop();
		}
		while (h.size() > 0) {
			current = h.pushPop(new HuffmanBranch(current, h.pop()));
		};
		return current;
	};

	var fromCodeLengths = function(lengths, count) {
		/*
			makes a Huffman Tree from the code lengths
			length count can optionally be provided
			both are arrays
		*/
		if (count == null) {
			count = [];
			for (var i = 0, l = lengths.length; i < l; i++) {
				var cl = lengths[i] || 0;
				if (count[cl] == null) {
					count[cl] = 1;
				} else {
					count[cl]++;
				}
			}
		}
		count[0] = 0;
		var codes = [0];
		var code = 0;
		for (var i = 1, l = count.length; i < l; i++) {
			code = (code + count[i - 1]) << 1;
			codes[i] = code;
		}

		var tree = new HuffmanNode();
		for (var i = 0, l = lengths.length; i < l; i++) {
			var length = lengths[i];
			if (length) {
				code = codes[length]++;
				tree.insertCode(code, length, i);
			}

		}
		return tree;
	};

	var defaultHLIT = new HuffmanNode(); //default HLIT tree

	(function(){
		var code = 0x30; // spec says 00110000
		for (var i = 0; i < 144; i++) {
			defaultHLIT.insertCode(code++, 8, i);
		}
		code = 0x190; //spec says 110010000
		for (var i = 144; i < 256; i++) {
			defaultHLIT.insertCode(code++, 9, i);
		}
		code = 0;
		for (var i = 256; i < 280; i++) {
			defaultHLIT.insertCode(code++, 7, i);
		}
		code = 0xc0 //spec says 11000000
		for (var i = 280; i < 288; i++) {
			defaultHLIT.insertCode(code++, 8, i);
		}
	})();

	var defaultHDIST = new HuffmanNode(); //default HDIST tree
	(function(){ 
		for (var i = 0; i < 32; i++) {
			defaultHDIST.insertCode(i, 5, i);
		}
	})();
	var printSymbols = function printSymbols(tree, depth) {
		if (tree.leaf) {
			console.log(tree.value, depth);
		} else {
			depth++;
			printSymbols(tree.left, depth);
			printSymbols(tree.right, depth);
		}
	};
	printSymbols(defaultHLIT, 0);




	module.exports.HuffmanNode = HuffmanNode;
	module.exports.fromFrequencies = fromFrequencies;
	module.exports.fromCodeLengths = fromCodeLengths;
})();

// parent = (self - 1) << 1
// leftChild = (self >> 1) + 1
// rightChild = (self >> 1) + 2