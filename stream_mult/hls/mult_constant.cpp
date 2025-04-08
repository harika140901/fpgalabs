#include "ap_fixed.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"
typedef ap_axiu<32, 0, 0, 0> ap32_t;
typedef hls::stream<ap32_t> stream_type;

void mult_constant(stream_type& in_data, stream_type& out_data, 
    ap_int<32> constant) {
#pragma HLS INTERFACE s_axilite register port=constant
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis port=in_data
#pragma HLS INTERFACE axis port=out_data

    while (!in_data.empty()) {
        ap32_t in;
        in_data.read(in);
        ap32_t out;
        out.data = in.data * constant;
        out.last = in.last;
        out.keep = in.keep;
        out_data.write(out);
    }

}