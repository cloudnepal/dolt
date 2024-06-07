// Copyright 2022-2023 Dolthub, Inc.
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

// Code generated by the FlatBuffers compiler. DO NOT EDIT.

package serial

import (
	flatbuffers "github.com/dolthub/flatbuffers/v23/go"
)

type StashList struct {
	_tab flatbuffers.Table
}

func InitStashListRoot(o *StashList, buf []byte, offset flatbuffers.UOffsetT) error {
	n := flatbuffers.GetUOffsetT(buf[offset:])
	return o.Init(buf, n+offset)
}

func TryGetRootAsStashList(buf []byte, offset flatbuffers.UOffsetT) (*StashList, error) {
	x := &StashList{}
	return x, InitStashListRoot(x, buf, offset)
}

func TryGetSizePrefixedRootAsStashList(buf []byte, offset flatbuffers.UOffsetT) (*StashList, error) {
	x := &StashList{}
	return x, InitStashListRoot(x, buf, offset+flatbuffers.SizeUint32)
}

func (rcv *StashList) Init(buf []byte, i flatbuffers.UOffsetT) error {
	rcv._tab.Bytes = buf
	rcv._tab.Pos = i
	if StashListNumFields < rcv.Table().NumFields() {
		return flatbuffers.ErrTableHasUnknownFields
	}
	return nil
}

func (rcv *StashList) Table() flatbuffers.Table {
	return rcv._tab
}

func (rcv *StashList) AddressMap(j int) byte {
	o := flatbuffers.UOffsetT(rcv._tab.Offset(4))
	if o != 0 {
		a := rcv._tab.Vector(o)
		return rcv._tab.GetByte(a + flatbuffers.UOffsetT(j*1))
	}
	return 0
}

func (rcv *StashList) AddressMapLength() int {
	o := flatbuffers.UOffsetT(rcv._tab.Offset(4))
	if o != 0 {
		return rcv._tab.VectorLen(o)
	}
	return 0
}

func (rcv *StashList) AddressMapBytes() []byte {
	o := flatbuffers.UOffsetT(rcv._tab.Offset(4))
	if o != 0 {
		return rcv._tab.ByteVector(o + rcv._tab.Pos)
	}
	return nil
}

func (rcv *StashList) MutateAddressMap(j int, n byte) bool {
	o := flatbuffers.UOffsetT(rcv._tab.Offset(4))
	if o != 0 {
		a := rcv._tab.Vector(o)
		return rcv._tab.MutateByte(a+flatbuffers.UOffsetT(j*1), n)
	}
	return false
}

const StashListNumFields = 1

func StashListStart(builder *flatbuffers.Builder) {
	builder.StartObject(StashListNumFields)
}
func StashListAddAddressMap(builder *flatbuffers.Builder, addressMap flatbuffers.UOffsetT) {
	builder.PrependUOffsetTSlot(0, flatbuffers.UOffsetT(addressMap), 0)
}
func StashListStartAddressMapVector(builder *flatbuffers.Builder, numElems int) flatbuffers.UOffsetT {
	return builder.StartVector(1, numElems, 1)
}
func StashListEnd(builder *flatbuffers.Builder) flatbuffers.UOffsetT {
	return builder.EndObject()
}