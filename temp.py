import math
from qick import SocIp

class AxisMatMux(SocIp):
    bindto = ['xilinx.com:user:axis_matmux:1.0']


    def __init__(self, description):
        # Initialize ip
        super().__init__(description)
        
        # Generics
        self.N_OUT = int(description['parameters']['N_OUT'])
        self.IN_COUNT_WIDTH = int(description['parameters']['IN_COUNT_WIDTH'])
        self.N_IN = 2 ** self.IN_COUNT_WIDTH
        self.output_dacs = []

#         # Default registers.
#         self.real_reg = self.MAXV
#         self.imag_reg = self.MAXV

#         # Register update.
#         self.update()

    def update(self):
        self.we_reg = 1
        self.we_reg = 0


    def configure_connections(self, soc):
        super().configure_connections(soc)
        
        # Loop over all enabled output ports
        for i in range(self.N_OUT):
            dac = None
            try:
                # what RFDC/matmux port does this generator drive?
                block, port, block_type = soc.metadata.trace_forward(self['fullpath'], f'm{i:02d}_axis', ["usp_rf_data_converter"])
                # port names are of the form 's00_axis'
                dac = port[1:3]
            except:
                pass
            self.output_dacs.append(dac)
        
        self.cfg['output_dacs'] = self.output_dacs
    
    @property
    def output_enable(self):
        reg = self.read(0x100)
        reg = reg >> 16
        # convert to indecies
        arr = []
        for i in range(16):
            if reg & (1 << i):
                arr.append(i)
                
        return arr
    
    @output_enable.setter
    def output_enable(self, output_indecies):
        # convert to bit map
        reg = 0
        for i in output_indecies:
            reg += 1 << i
        
        # shift reg to correct position
        reg = reg << 16
        self.write(0x100, reg)
    
    @property
    def shift_matrix(self):
        matrix = []
        for output_channel in range(self.N_OUT):
            matrix_row = []
            for input_channel_group in range(math.ceil(self.N_IN / 4)):
                address = output_channel << 8
                address += input_channel_group * 4
                reg = self.read(address)
                for i, input_channel in enumerate(range(input_channel_group*4, min(self.N_IN, input_channel_group*4+4))):
                    matrix_row.append( (reg >> (8 * i)) & 0xF )
            matrix.append(matrix_row)
        return matrix
    
    @shift_matrix.setter
    def shift_matrix(self, matrix):
        # Validate matrix dimensions
        if len(matrix) != self.N_OUT:
        raise ValueError(f"Matrix must have {self.N_OUT} rows (outputs)")
    for row in matrix:
        if len(row) != self.N_IN:
            raise ValueError(f"Each row must have {self.N_IN} columns (inputs)")
        
    # Write matrix values to registers
    for output_channel in range(self.N_OUT):
        for input_channel_group in range(math.ceil(self.N_IN / 4)):
            # Calculate register value for this group of 4 inputs
            reg = 0
            for i in range(4):
                input_channel = input_channel_group * 4 + i
                if input_channel < self.N_IN:
                    # Shift value is in the lowest 4 bits (0xF)
                    shift_value = matrix[output_channel][input_channel] & 0xF
                    reg |= (shift_value << (8 * i))
            
            # Calculate register address
            address = output_channel << 8
            address += input_channel_group * 4
            
            # Write the register
            self.write(address, reg)