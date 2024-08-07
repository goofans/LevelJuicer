	# Boy image utility for converting textures
extends Node
class_name BOY_IMAGE


		# - FUNCTIONS -
	# UTILITIES
static func convert_texture(filePath:String) -> ImageTexture:
	var file:FileAccess = FileAccess.open(filePath, FileAccess.READ)
	
		# Read boyi file
		# TODO - Handle Masks
	var _magic:int = file.get_32()
	var _version:int = file.get_32()
	var _width:int = file.get_16()
	var _height:int = file.get_16()
	var _unusedWidth:int = file.get_16()
	var _unusedHeight:int = file.get_16()
	var _ktxCompressedSize:int = file.get_32()
	var _ktxDecompressedSize:int = file.get_32()
	var _maskWidth:int = file.get_16()
	var _maskHeight:int = file.get_16()
	var _compressedMaskSize:int = file.get_32()
	var _decompressedMaskSize:int = file.get_32()
	var _ktxCompressedData:PackedByteArray = file.get_buffer(_ktxCompressedSize)
	
		# Decompress ktx Data
	var _ktxDecompressedData:PackedByteArray = _ktxCompressedData.decompress(_ktxDecompressedSize, FileAccess.CompressionMode.COMPRESSION_ZSTD)
	_ktxDecompressedData = _ktxDecompressedData.slice(68, 68 + (_width * _height * 4))
		# Turn KTX Data into Image
	var _ktxImage:Image = Image.create_from_data(_width, _height, false, Image.FORMAT_RGBA8, _ktxDecompressedData)

		# Return Texture from Image
	return ImageTexture.create_from_image(_ktxImage)
