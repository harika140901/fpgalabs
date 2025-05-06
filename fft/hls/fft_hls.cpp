#include "ap_fixed.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"

void fft_hls(hls::stream<cmpx_t> &in_s, hls::stream<cmpx_t> &out_s) {
    #pragma HLS interface axis port=in_s
    #pragma HLS interface axis port=out_s
    #pragma HLS interface s_axilite port=return bundle=CTRL
    #pragma HLS dataflow
  
    // Local buffers for one 32-point block
    static cmpx_t buffer[32];
    // 1) Read 32 samples from stream (bit-reverse ordering)
    for (int i = 0; i < 32; i++) {
      #pragma HLS pipeline II=1
      buffer[bitrev(i)] = in_s.read();
    }
    // 2) FFT butterfly computation (5 stages)
    int stride = 16;
    for (int stage = 0; stage < 5; stage++) {
      for (int j = 0; j < 32; j += 2*stride) {
        for (int k = 0; k < stride; k++) {
          #pragma HLS pipeline II=1
          cmpx_t a = buffer[j+k];
          cmpx_t b = buffer[j+k+stride] * twiddle[stage][k];
          buffer[j+k]        = a + b;
          buffer[j+k+stride] = a - b;
        }
      }
      stride >>= 1;
    }
    // 3) Write 32 results to output stream
    for (int i = 0; i < 32; i++) {
      #pragma HLS pipeline II=1
      out_s.write(buffer[i]);
    }
  }
  


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