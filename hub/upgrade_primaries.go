// Copyright (c) 2017-2022 VMware, Inc. or its affiliates
// SPDX-License-Identifier: Apache-2.0

package hub

import (
	"context"
	"path/filepath"
	"strconv"

	"golang.org/x/xerrors"

	"github.com/greenplum-db/gpupgrade/greenplum"
	"github.com/greenplum-db/gpupgrade/idl"
)

func UpgradePrimaries(agentConns []*idl.Connection, source *greenplum.Cluster, intermediate *greenplum.Cluster, action idl.PgOptions_Action, linkMode bool) error {
	request := func(conn *idl.Connection) error {
		intermediatePrimaries := intermediate.SelectSegments(func(seg *greenplum.SegConfig) bool {
			return seg.IsOnHost(conn.Hostname) && seg.IsPrimary() && !seg.IsCoordinator()
		})

		var opts []*idl.PgOptions
		for _, intermediatePrimary := range intermediatePrimaries {
			sourcePrimary := source.Primaries[intermediatePrimary.ContentID]

			opt := &idl.PgOptions{
				Action:        action,
				Role:          intermediatePrimary.Role,
				ContentID:     int32(intermediatePrimary.ContentID),
				Mode:          idl.PgOptions_segment,
				LinkMode:      linkMode,
				TargetVersion: intermediate.Version.String(),
				OldBinDir:     filepath.Join(source.GPHome, "bin"),
				OldDataDir:    sourcePrimary.DataDir,
				OldPort:       strconv.Itoa(sourcePrimary.Port),
				OldDBID:       strconv.Itoa(int(sourcePrimary.DbID)),
				NewBinDir:     filepath.Join(intermediate.GPHome, "bin"),
				NewDataDir:    intermediatePrimary.DataDir,
				NewPort:       strconv.Itoa(intermediatePrimary.Port),
				NewDBID:       strconv.Itoa(int(intermediatePrimary.DbID)),
				Tablespaces:   source.Tablespaces[int32(intermediatePrimary.DbID)],
			}

			opts = append(opts, opt)
		}

		req := &idl.UpgradePrimariesRequest{Action: action, Opts: opts}
		_, err := conn.AgentClient.UpgradePrimaries(context.Background(), req)
		if err != nil {
			return xerrors.Errorf("%s primary segment on host %s: %w", action, conn.Hostname, err)
		}

		return nil
	}

	return ExecuteRPC(agentConns, request)
}
