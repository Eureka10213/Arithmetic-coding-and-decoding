# Arithmetic-coding-and-decoding
Arithmetic coding and decoding.Block coding.MATLAB
Given the probability distribution of source symbols (26 English letters and space), based on matlab, arithmetic coding and decoding of messages in text documents are implemented. In the process of arithmetic coding, the longer the message, the more decimal places. If the precision required by the coding exceeds the precision of the development environment, the coding will fail. To solve this problem, the idea of group coding is adopted. Before coding, the number of symbols in each group is specified.For example, 5 symbols are coded at a time, and the coding results of each group are separated by a space as an identifier.Space is recognized during decoding and each group is decoded in turn.
Attention: there should not be any punctuation marks in the test text document, if not, please find a way to remove them.
