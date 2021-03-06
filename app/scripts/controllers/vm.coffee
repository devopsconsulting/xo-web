'use strict'

angular.module('xoWebApp')
  .controller 'VmCtrl', (
    $scope, $stateParams
    xoApi, xo
    sizeToBytesFilter, bytesToSizeFilter
    modal
    dateFilter
  ) ->
    {get} = xo
    $scope.$watch(
      -> xo.revision
      ->
        VM = $scope.VM = get $stateParams.id

        {byTypes} = xo
        $scope.hosts = byTypes.host

        return unless VM?

        # For the edition of this VM.
        $scope.memorySize = bytesToSizeFilter VM.memory.size

        # build VDI list of this VM
        $scope.VDIs = []
        for VBD in VM.$VBDs
          VDI = get (get VBD)?.VDI
          $scope.VDIs.push VDI if VDI?
    )

    # AngularUI select2 component settings
    $scope.select2Options =
      'multiple': true
      'simple_tags': true
      'tags': []

    $scope.startVM = xo.vm.start
    $scope.stopVM = xo.vm.stop
    $scope.force_stopVM = (id) -> xo.vm.stop id, true
    $scope.rebootVM = xo.vm.restart
    $scope.force_rebootVM = (id) -> xo.vm.restart id, true
    $scope.migrateVM = xo.vm.migrate
    $scope.destroyVM = (id) ->
      modal.confirm({
        title: 'VM deletion'
        message: 'Are you sure you want to delete this VM? (including its disks)'
      }).then ->
        # FIXME: provides a way to not delete its disks.
        xo.vm.delete id, true

    $scope.saveSnapshot = (id, $data) ->
      snapshot = get (id)

      result = {
        id: snapshot.UUID
        name_label: $data
      }

      if $data isnt snapshot.name_label
        console.log "new name recorded"
        result.name_label = $data

      xoApi.call 'vm.set', result

    $scope.saveVM = ($data) ->
      {VM} = $scope
      {CPUs, memory, name_label, name_description} = $data

      $data = {
        id: VM.UUID
      }
      if memory isnt $scope.memorySize and (memory = sizeToBytesFilter memory)
        $data.memory = memory
        $scope.memorySize = bytesToSizeFilter memory
      if CPUs isnt VM.CPUs.number
        $data.CPUs = +CPUs
      if name_label isnt VM.name_label
        $data.name_label = name_label
      if name_description isnt VM.name_description
        $data.name_description = name_description

      xoApi.call 'vm.set', $data

    # VDI
    selected = $scope.selectedVDIs = {}

    $scope.newVDIs = []

    $scope.addVDI = ->
      $scope.newVDIs.push {
        # Fake (unique) identifier needed by Angular.JS
        id: Math.random()
      }
    ## TODO: Use Angular XEditable Row

    $scope.deleteVDI = (UUID) ->
      modal.confirm({
        title: 'Disk deletion'
        message: 'Are you sure you want to delete this disk? This operation is irreversible'
      }).then ->
        xoApi.call 'vdi.delete', {id: UUID}

    $scope.disconnectVBD = (UUID) ->
      console.log "Disconnect VBD #{UUID}"

      xoApi.call 'vbd.disconnect', {id: UUID}

    $scope.snapshotVM = (id, vm_name) ->
      date = dateFilter Date.now(), 'yyyy-MM-ddTHH:mmZ'
      snapshot_name = "#{vm_name}_#{date}"
      console.log "Snapshot #{snapshot_name} from VM #{id}"
      xo.vm.createSnapshot id, snapshot_name

    $scope.deleteSnapshot = (id) ->
      console.log "Delete snapshot #{id}"
      modal.confirm({
        title: 'Snapshot deletion'
        message: 'Are you sure you want to delete this snapshot? (including its disks)'
      }).then ->
        # FIXME: provides a way to not delete its disks.
        xo.vm.delete id, true

    $scope.deleteLog = (id) ->
      console.log "Remove log #{id}"
      xo.log.delete id

    $scope.revertSnapshot = (id) ->
      console.log "Revert snapshot to #{id}"
      modal.confirm({
        title: 'Revert to snapshot'
        message: 'Are you sure you want to revert your VM to this snapshot? The VM will be halted and this operation is irreversible'
      }).then ->
        xo.vm.revert id

    $scope.osType = (osName) ->
      switch osName
        when 'debian','ubuntu','centos','suse','redhat','oracle','gentoo'
          'linux'
        when 'windows'
          'windows'
        else
          'other'
