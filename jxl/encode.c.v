module jxl

#flag linux -L/usr/lib
#flag linux -ljxl
#flag linux -I/usr/include
#include <jxl/encode.h>

@[typedef]
pub struct C.JxlEncoder {}

@[typedef]
pub struct C.JxlEncoderFrameSettings {}

pub enum JxlEncoderStatus {
	success          = 0
	error            = 1
	need_more_output = 2
}

pub enum JxlEncoderError {
	ok            = 0
	generic       = 1
	oom           = 2
	jbrd          = 3
	bad_input     = 4
	not_supported = 0x80
	api_usage     = 0x81
}

pub enum JxlEncoderFrameSettingId {
	effort                           = 0
	decoding_speed                   = 1
	resampling                       = 2
	extra_channel_resampling         = 3
	already_downsampled              = 4
	photon_noise                     = 5
	noise                            = 6
	dots                             = 7
	patches                          = 8
	epf                              = 9
	gaborish                         = 10
	modular                          = 11
	keep_invisible                   = 12
	group_order                      = 13
	group_order_center_x             = 14
	group_order_center_y             = 15
	responsive                       = 16
	progressive_ac                   = 17
	qprogressive_ac                  = 18
	progressive_dc                   = 19
	channel_colors_global_percent    = 20
	channel_colors_group_percent     = 21
	palette_colors                   = 22
	lossy_palette                    = 23
	color_transform                  = 24
	modular_color_space              = 25
	modular_group_size               = 26
	modular_predictor                = 27
	modular_ma_tree_learning_percent = 28
	modular_nb_prev_channels         = 29
	jpeg_recon_cfl                   = 30
	frame_index_box                  = 31
	brotli_effort                    = 32
	jpeg_compress_boxes              = 33
	buffering                        = 34
	jpeg_keep_exif                   = 35
	jpeg_keep_xmp                    = 36
	jpeg_keep_jumbf                  = 37
	use_full_image_heuristics        = 38
	disable_perceptual_heuristics    = 39
	fill_enum                        = 65535
}

pub fn C.JxlEncoderCreate(memory_manager &C.JxlMemoryManager) &C.JxlEncoder
pub fn C.JxlEncoderReset(enc &C.JxlEncoder)
pub fn C.JxlEncoderDestroy(enc &C.JxlEncoder)
pub fn C.JxlEncoderSetCms(enc &C.JxlEncoder, cms &C.JxlCmsInterface)
pub fn C.JxlEncoderSetParallelRunner(enc &C.JxlEncoder, parallel_runner JxlParallelRunner, parallel_runner_opaque voidptr) JxlEncoderStatus
pub fn C.JxlEncoderGetError(enc &C.JxlEncoder) JxlEncoderError
pub fn C.JxlEncoderProcessOutput(enc &C.JxlEncoder, next_out &&u8, avail_out &usize) JxlEncoderStatus
pub fn C.JxlEncoderSetFrameHeader(frame_settings &C.JxlEncoderFrameSettings, frame_header &C.JxlFrameHeader) JxlEncoderStatus
pub fn C.JxlEncoderSetExtraChannelBlendInfo(frame_settings &C.JxlEncoderFrameSettings, index usize, blend_info &C.JxlBlendInfo) JxlEncoderStatus
pub fn C.JxlEncoderSetFrameName(frame_settings &C.JxlEncoderFrameSettings, frame_name &char) JxlEncoderStatus
pub fn C.JxlEncoderSetFrameBitDepth(frame_settings &C.JxlEncoderFrameSettings, bit_depth &C.JxlBitDepth) JxlEncoderStatus
pub fn C.JxlEncoderAddJPEGFrame(frame_settings &C.JxlEncoderFrameSettings, buffer &u8, size usize) JxlEncoderStatus
pub fn C.JxlEncoderAddImageFrame(frame_settings &C.JxlEncoderFrameSettings, pixel_format &C.JxlPixelFormat, buffer voidptr, size usize) JxlEncoderStatus

pub struct C.JxlEncoderOutputProcessor {
	opaque                 voidptr
	get_buffer             fn (opaque voidptr, size &usize) voidptr
	release_buffer         fn (opaque voidptr, written_bytes usize)
	seek                   fn (opaque voidptr, position u64)
	set_finalized_position fn (opaque voidptr, finalized_position u64)
}

pub fn C.JxlEncoderSetOutputProcessor(encoder &C.JxlEncoder, output_processor &C.JxlEncoderOutputProcessor) JxlEncoderStatus
pub fn C.JxlEncoderFlushInput(encoder &C.JxlEncoder) JxlEncoderStatus

pub struct C.JxlChunkedFrameInputSource {
	opaque                          voidptr
	get_color_channels_pixel_format fn (opaque voidptr, pixel_format &C.JxlPixelFormat) voidptr
	get_color_channel_data_at       fn (opaque voidptr, xpos usize, ypos usize, xsize usize, ysize usize, row_offset &usize) voidptr
	get_extra_channel_pixel_format  fn (opaque voidptr, ec_index usize, pixel_format &C.JxlPixelFormat)
	get_extra_channel_data_at       fn (opaque voidptr, ec_index usize, xpos usize, ypos usize, xsize usize, ysize usize, row_offset &usize) voidptr
	release_buffer                  fn (opaque voidptr, buf voidptr)
}

pub fn C.JxlEncoderAddChunkedFrame(frame_settings &C.JxlEncoderFrameSettings, is_last_frame bool, chunked_frame_input &C.JxlChunkedFrameInputSource) JxlEncoderStatus
pub fn C.JxlEncoderSetExtraChannelBuffer(frame_settings &C.JxlEncoderFrameSettings, pixel_format &C.JxlPixelFormat, buffer voidptr, size usize, index u32) JxlEncoderStatus
pub fn C.JxlEncoderAddBox(enc &C.JxlEncoder, type, JxlBoxType, contents &u8, size usize, compress_box bool) JxlEncoderStatus
pub fn C.JxlEncoderUseBoxes(enc &C.JxlEncoder) JxlEncoderStatus
pub fn C.JxlEncoderCloseBoxes(enc &C.JxlEncoder)
pub fn C.JxlEncoderCloseFrames(enc &C.JxlEncoder)
pub fn C.JxlEncoderCloseInput(enc &C.JxlEncoder)
pub fn C.JxlEncoderSetColorEncoding(enc &C.JxlEncoder, color &C.JxlColorEncoding) JxlEncoderStatus
pub fn C.JxlEncoderSetICCProfile(enc &C.JxlEncoder, icc_profile &u8, size usize) JxlEncoderStatus
pub fn C.JxlEncoderInitBasicInfo(info &C.JxlBasicInfo)
pub fn C.JxlEncoderInitFrameHeader(frame_header &C.JxlFrameHeader)
pub fn C.JxlEncoderInitBlendInfo(blend_info &C.JxlBlendInfo)
pub fn C.JxlEncoderSetBasicInfo(enc &C.JxlEncoder, info &C.JxlBasicInfo) JxlEncoderStatus
pub fn C.JxlEncoderSetUpsamplingMode(enc &C.JxlEncoder, factor i64, mode i64) JxlEncoderStatus
pub fn C.JxlEncoderInitExtraChannelInfo(enc &C.JxlEncoder, info &C.JxlExtraChannelInfo) JxlEncoderStatus
pub fn C.JxlEncoderSetExtraChannelInfo(enc &C.JxlEncoder, index usize, info &C.JxlExtraChannelInfo) JxlEncoderStatus
pub fn C.JxlEncoderSetExtraChannelName(enc &C.JxlEncoder, index usize, name &C.char, size usize) JxlEncoderStatus
pub fn C.JxlEncoderFrameSettingsSetOption(frame_settings &C.JxlEncoderFrameSettings, option JxlEncoderFrameSettingId, value i64) JxlEncoderStatus
pub fn C.JxlEncoderFrameSettingsSetFloatOption(frame_settings &C.JxlEncoderFrameSettings, option JxlEncoderFrameSettingId, value f32) JxlEncoderStatus
pub fn C.JxlEncoderUseContainer(enc &C.JxlEncoder, use_container bool) JxlEncoderStatus
pub fn C.JxlEncoderStoreJPEGMetadata(enc &C.JxlEncoder, store_jpeg_metadata bool) JxlEncoderStatus
pub fn C.JxlEncoderSetCodestreamLevel(enc &C.JxlEncoder, level int) JxlEncoderStatus
pub fn C.JxlEncoderGetRequiredCodestreamLevel(enc &C.JxlEncoder) int
pub fn C.JxlEncoderSetLossless(enc &C.JxlEncoder, lossless bool) JxlEncoderStatus
pub fn C.JxlEncoderSetFrameLossless(frame_settings &C.JxlEncoderFrameSettings, lossless bool) JxlEncoderStatus
pub fn C.JxlEncoderSetFrameDistance(frame_settings &C.JxlEncoderFrameSettings, distance f32) JxlEncoderStatus
pub fn C.JxlEncoderSetExtraChannelDistance(frame_settings &C.JxlEncoderFrameSettings, index usize, distance f32) JxlEncoderStatus
pub fn C.JxlEncoderDistanceFromQuality(quality f32) f32
pub fn C.JxlEncoderFrameSettingsCreate(enc &C.JxlEncoder, source &C.JxlEncoderFrameSettings) &C.JxlEncoderFrameSettings
pub fn C.JxlColorEncodingSetToSRGB(color_encoding &C.JxlColorEncoding, is_gray bool) JxlEncoderStatus
pub fn C.JxlColorEncodingSetToLinearSRGB(color_encoding &C.JxlColorEncoding, is_gray bool)
pub fn C.JxlEncoderAllowExpertOptions(enc &C.JxlEncoder)

type JxlDebugImageCallback = fn (opaque voidptr, label &char, xsize usize, ysize usize, color &C.JxlColorEncoding, pixels &u16)

pub fn C.JxlEncoderSetDebugImageCallback(enc &C.JxlEncoder, callback JxlDebugImageCallback, opaque voidptr)
pub fn C.JxlEncoderCollectStats(frame_settings &C.JxlEncoderFrameSettings, stats &C.JxlEncoderStats)
