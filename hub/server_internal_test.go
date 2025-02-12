// Copyright (c) 2017-2022 VMware, Inc. or its affiliates
// SPDX-License-Identifier: Apache-2.0

package hub

import (
	"bytes"
	"reflect"
	"testing"

	"github.com/greenplum-db/gpupgrade/testutils"
	"github.com/greenplum-db/gpupgrade/upgrade"
)

func TestConfig(t *testing.T) {
	// "stream" refers to the io.Writer/Reader interfaces.
	t.Run("saves itself to the provided stream", func(t *testing.T) {
		source, target := testutils.CreateMultinodeSampleClusterPair("/tmp")
		intermediate := source

		// NOTE: we explicitly do not name the struct members here, to ensure
		// that the test fails to compile if you add new members to Config but
		// forget to add them to this test. Be kind and document those that are
		// not clear with comments.
		original := &Config{
			"logArchiveDir",
			source,
			intermediate,
			target,
			12345,           // Port
			54321,           // AgentPort
			false,           // LinkMode
			false,           // UseHbaHostnames
			upgrade.NewID(), // UpgradeID
		}

		buf := new(bytes.Buffer)
		err := original.Save(buf)
		if err != nil {
			t.Errorf("Save() returned error %+v", err)
		}

		// Save the buffer contents for later debugging (otherwise they'll be
		// consumed by Load()).
		contents := buf.String()

		duplicate := new(Config)
		err = duplicate.Load(buf)
		if err != nil {
			t.Errorf("Load() returned error %+v", err)
		}

		if !reflect.DeepEqual(original, duplicate) {
			// XXX This error message is less useful than it could be, because
			// %#v doesn't expand struct pointers recursively.
			t.Errorf("save-load cycle resulted in %#v, want %#v", duplicate, original)
			t.Logf("buffer contents:\n%s", contents)
		}
	})
}
