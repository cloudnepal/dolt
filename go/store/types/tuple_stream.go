// Copyright 2021 Dolthub, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package types

import (
	"context"
	"encoding/binary"
	"errors"
	"io"

	"github.com/dolthub/dolt/go/libraries/utils/iohelp"
)

// TupleWriter is an interface for an object that supports Types.Tuples being written to it
type TupleWriter interface {
	// WriteTuples writes the provided tuples
	WriteTuples(...Tuple) error
	// CopyFrom reads tuples from a reader and writes them
	CopyFrom(TupleReader) error
}

// TupleReader is an interface for an object that supports reading types.Tuples
type TupleReader interface {
	// Read reades the next tuple from the TupleReader
	Read() (Tuple, error)
}

// Closer is an interface for a class that can be closed
type Closer interface {
	// Close should release any underlying resources
	Close(context.Context) error
}

// TupleWriteCloser is an interface for a TupleWriter that has a Close method
type TupleWriteCloser interface {
	TupleWriter
	Closer
}

// TupleReadCloser is an interface for a TupleReader that has a Close method
type TupleReadCloser interface {
	TupleReader
	Closer
}

type tupleWriterImpl struct {
	wr io.Writer
}

// NewTupleWriter returns a TupleWriteCloser that writes tuple data to the supplied io.Writer
func NewTupleWriter(wr io.Writer) TupleWriteCloser {
	return &tupleWriterImpl{wr: wr}
}

func (twr *tupleWriterImpl) write(t Tuple) error {
	size := len(t.buff)

	var sizeBytes [4]byte
	binary.BigEndian.PutUint32(sizeBytes[:], uint32(size))
	err := iohelp.WriteAll(twr.wr, sizeBytes[:])
	if err != nil {
		return err
	}

	return iohelp.WriteAll(twr.wr, t.buff)
}

// WriteTuples writes the provided tuples
func (twr *tupleWriterImpl) WriteTuples(tuples ...Tuple) error {
	for _, t := range tuples {
		err := twr.write(t)

		if err != nil {
			return err
		}
	}

	return nil
}

// CopyFrom reads tuples from a reader and writes them
func (twr *tupleWriterImpl) CopyFrom(rd TupleReader) error {
	for {
		t, err := rd.Read()

		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		err = twr.write(t)

		if err != nil {
			return err
		}
	}

	return nil
}

// Close should release any underlying resources
func (twr *tupleWriterImpl) Close(context.Context) error {
	closer, ok := twr.wr.(io.Closer)
	if ok {
		return closer.Close()
	}

	return nil
}

type tupleReaderImpl struct {
	nbf *NomsBinFormat
	vrw ValueReadWriter
	rd  io.Reader
}

// NewTupleReader returns a TupleReadCloser that reads tuple data from the supplied io.Reader
func NewTupleReader(nbf *NomsBinFormat, vrw ValueReadWriter, rd io.Reader) TupleReadCloser {
	return &tupleReaderImpl{nbf: nbf, vrw: vrw, rd: rd}
}

// Read reades the next tuple from the TupleReader
func (trd *tupleReaderImpl) Read() (Tuple, error) {
	sizeBytes, err := iohelp.ReadNBytes(trd.rd, 4)
	if err != nil {
		return Tuple{}, err
	}

	size := binary.BigEndian.Uint32(sizeBytes)
	data, err := iohelp.ReadNBytes(trd.rd, int(size))
	if err != nil {
		if err == io.EOF {
			return Tuple{}, errors.New("corrupt tuple stream")
		}
		return Tuple{}, err
	}

	return Tuple{valueImpl{trd.vrw, trd.nbf, data, nil}}, nil
}

// Close should release any underlying resources
func (trd *tupleReaderImpl) Close(context.Context) error {
	closer, ok := trd.rd.(io.Closer)
	if ok {
		return closer.Close()
	}

	return nil
}