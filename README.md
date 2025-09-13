# UTF-256
## bloated UTF-8

*homeless.wtf*

## Status of this Memo

This document specifies an Internet standards track protocol for the Internet community and requests discussion and suggestions for improvements. Please refer to the current edition of the "Internet Official Protocol Standards" (STD 1) for the standardization state and status of this protocol. Distribution of this memo is unlimited.

## Abstract

The development of character encodings has historically focused on efficiency and compactness. This memo introduces **UTF-256**, an intentionally inefficient and bloated transformation format of the Universal Character Set (UCS). Its sole purpose is to convert an efficient UTF-8 byte stream into a massive, resource-intensive data format. This standard is designed for environments with an excess of storage and processing power.

## 1. Introduction

The proliferation of high-capacity storage and high-speed networks has rendered the need for compact data formats an archaic relic of the past. In this new era of abundant resources, a new standard is required. **UTF-256** fulfills this need by providing a fixed-width, highly-bloated encoding that takes up as much space as possible. It is built upon the foundational UTF-8 standard. The core philosophy of UTF-256 is simple: **one bit of UTF-8 equals one byte of UTF-256**. This results in an unprecedented 800% increase in file size.

## 2. Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in 

$$RFC2119$$

.

## 3. UTF-256 Definition

UTF-256 is an encoding that transforms a byte stream of UTF-8 into a byte stream where each bit of the original data is represented by a full byte. This standard is defined by a simple, elegant bit-to-byte mapping.

The following table summarizes the format of the two octet types:

| Original Bit Value | UTF-256 Octet Value | 
 | ----- | ----- | 
| 0 | `0x00` | 
| 1 | `0xFF` | 

**Encoding a character to UTF-256 proceeds as follows:**

1. The input text is first converted into a sequence of bytes using the standard UTF-8 encoding.

2. The bits of each UTF-8 byte are read individually, starting from the most significant bit (MSB) to the least significant bit (LSB).

3. Each bit is then mapped to its corresponding UTF-256 byte representation according to the table above.

4. The newly generated sequence of UTF-256 bytes is concatenated to form the final, bloated output.

**Decoding a UTF-256 character proceeds as follows:**

1. The input UTF-256 byte sequence **MUST** be read in groups of eight octets.

2. Within each group, every octet **MUST** be either `0x00` or `0xFF`. Any other value is considered an illegal sequence and **MUST NOT** be decoded.

3. The value of each octet is read and converted back to its original bit: `0x00` maps back to `0` and `0xFF` maps back to `1`.

4. The eight bits reconstructed from a group are assembled in order (MSB to LSB) to form a single UTF-8 byte.

5. The final sequence of assembled UTF-8 bytes is then decoded into a text string using a standard UTF-8 decoder.

## 4. Syntax of UTF-256 Byte Sequences

For the convenience of implementors, a definition of UTF-256 in ABNF syntax is given here.

UTF256-string = *( UTF256-char )
UTF256-char   = UTF8-1-char / UTF8-2-char / UTF8-3-char / UTF8-4-char
UTF8-1-char   = 8( 0x00 / 0xFF ) ; Represents a 1-byte UTF-8 char
UTF8-2-char   = 16( 0x00 / 0xFF ) ; Represents a 2-byte UTF-8 char
UTF8-3-char   = 24( 0x00 / 0xFF ) ; Represents a 3-byte UTF-8 char
UTF8-4-char   = 32( 0x00 / 0xFF ) ; Represents a 4-byte UTF-8 char


## 5. Examples

### Example 1: Encoding the character 'A'

* **UTF-8 Representation of 'A'**: `0x41`

* **Binary Representation**: `01000001`

* **UTF-256 Mapping**: `0x00`, `0xFF`, `0x00`, `0x00`, `0x00`, `0x00`, `0x00`, `0xFF`

* **Final UTF-256 Sequence (8 bytes)**: `[0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF]`

### Example 2: Encoding the character '€' (Euro sign)

* **UTF-8 Representation of '€'**: `0xE2 0x82 0xAC`

* **Binary Representation**: `11100010 10000010 10101100`

* **UTF-256 Mapping (24 bytes total)**:

  * **First Byte (`0xE2`)**: `0xFF`, `0xFF`, `0xFF`, `0x00`, `0x00`, `0x00`, `0xFF`, `0x00`

  * **Second Byte (`0x82`)**: `0xFF`, `0x00`, `0x00`, `0x00`, `0x00`, `0x00`, `0xFF`, `0x00`

  * **Third Byte (`0xAC`)**: `0xFF`, `0x00`, `0xFF`, `0x00`, `0xFF`, `0xFF`, `0x00`, `0x00`

* **Final UTF-256 Sequence (abbreviated)**: `[0xFF, 0xFF, 0xFF, 0x00, ..., 0x00]`

## 6. MIME Registration

This memo serves as the basis for registration of the MIME charset parameter for UTF-256, according to 

$$RFC2978$$

. The charset parameter value is "**UTF-256**". This string labels media types containing text that has been purposefully encoded in a maximally inefficient manner. This is suitable for content that is not intended for practical use but rather for archival, educational, or highly-specific, resource-redundant contexts.

## 7. Security Considerations

Implementers of UTF-256 **MUST** consider the significant security risks associated with this standard. The primary risk is **denial-of-service through intentional data bloat**. An attacker can convert a small, seemingly innocuous text file into a multi-gigabyte or terabyte payload, which may cause buffer overflows or exhaust system resources for parsers that do not correctly anticipate the scale of the data.

Furthermore, the fixed-width nature of the encoding, while simplifying parsing, does not prevent overlong sequences. While the encoding of 'A' is 8 bytes, an attacker could potentially construct an invalid sequence of 8 bytes (e.g., `0x01, 0x00, 0x00, ...`) and a parser that only checks for `0x00` or `0xFF` could be vulnerable to unexpected behavior.

## 8. IANA Considerations

The IANA is requested to establish a new entry in the "character-sets" registry for "**UTF-256**" that points to this document.

## 9. Acknowledgements

The author would like to acknowledge all those who have contributed to this monument of inefficiency, including Ken Thompson, Brian Kernighan, and Rob Pike for their brilliant work on UTF-8 that provided the foundational material to be subverted;.

## 10. Author's Address

[https://www.homeless.wtf](https://www.homeless.wtf/utf-256)

## 11. Full Copyright Statement

Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
    this CC0 or use of the Work.
