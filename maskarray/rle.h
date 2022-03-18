#define MIN_OCCURANCES          3
#define CHUNK_INCREMENT         0x1000
#define PAGE_SIZE               0x1000000
#define MAX_SYMBOL_LENGTH       (PAGE_SIZE - 1)

#define PAGE_ROWBREAK           0x00000000
#define SUBSTITUTE_SKIP         0x00000000

#define PAGE_ZEROS              0x00
#define PAGE_ONES               0x01
#define PAGE_PATTERN            0x02
#define PAGE_FIRST_SYMBOL_TABLE 0x03
#define PAGE_FIRST_ROW_TABLE    0xFF
