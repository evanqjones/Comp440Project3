extends RefCounted

const DATA = {
  "fps": 24,
  "source_file": "monster_all_phases_connected.blend",
  "phases": {
    "0": {
      "file": "models/phase_0.glb",
      "label": "Idle"
    },
    "1": {
      "file": "models/phase_1.glb",
      "label": "Search"
    },
    "2": {
      "file": "models/phase_2.glb",
      "label": "Chase"
    },
    "3": {
      "file": "models/phase_3.glb",
      "label": "Spider"
    }
  },
  "animations": {
    "chase0": {
      "phase": 0,
      "loop": true,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_0.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.2947423477447413,
        0.10076985400975003,
        -1.3347997512566625
      ],
      "sampled_bounds_max": [
        1.5568500543756425,
        4.776136449284083,
        4.2679300219351655
      ]
    },
    "idle0": {
      "phase": 0,
      "loop": true,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_0.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.035122700714281,
        0.1009108468770833,
        -1.006305552458297
      ],
      "sampled_bounds_max": [
        0.987476101730272,
        5.368000081486231,
        1.2358118191381173
      ]
    },
    "search0": {
      "phase": 0,
      "loop": true,
      "start_frame": 1,
      "end_frame": 30,
      "duration_seconds": 1.2083333333333333,
      "file": "models/phase_0.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.496762288297111,
        -0.19653675374527846,
        -0.737043083762336
      ],
      "sampled_bounds_max": [
        3.305992233822556,
        2.879353785209986,
        2.9834287384945504
      ]
    },
    "walk0": {
      "phase": 0,
      "loop": true,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_0.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.3730379055942235,
        -0.12459527985577257,
        -0.5596414414966089
      ],
      "sampled_bounds_max": [
        1.5104650271260072,
        4.6326370748944345,
        1.8906999734772723
      ]
    },
    "chase1": {
      "phase": 1,
      "loop": true,
      "start_frame": 1,
      "end_frame": 27,
      "duration_seconds": 1.0833333333333333,
      "file": "models/phase_1.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.5851921426600317,
        -0.04872451095652153,
        -1.4403418216853798
      ],
      "sampled_bounds_max": [
        1.4455573069386831,
        3.5645326751517743,
        2.9533040368871304
      ]
    },
    "idle1": {
      "phase": 1,
      "loop": true,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_1.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.0957874158842758,
        0.10091238646585894,
        -1.0063058369912463
      ],
      "sampled_bounds_max": [
        1.0538421136549332,
        5.294000067119548,
        1.235813866512065
      ]
    },
    "search1": {
      "phase": 1,
      "loop": true,
      "start_frame": 1,
      "end_frame": 27,
      "duration_seconds": 1.0833333333333333,
      "file": "models/phase_1.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -2.8337604417986952,
        -0.027267292333438137,
        -0.7452639865072054
      ],
      "sampled_bounds_max": [
        2.7646743063486756,
        4.008207716350505,
        3.1299379571836043
      ]
    },
    "walk1": {
      "phase": 1,
      "loop": true,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_1.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -1.3722738621235717,
        -0.11990356661504364,
        -0.5457511287545994
      ],
      "sampled_bounds_max": [
        1.6205413838233962,
        4.581612266902873,
        1.8906880721013595
      ]
    },
    "chase2": {
      "phase": 2,
      "loop": true,
      "start_frame": 1,
      "end_frame": 31,
      "duration_seconds": 1.25,
      "file": "models/phase_2.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -3.3932689250364003,
        0.05485968963720955,
        -3.01832257657956
      ],
      "sampled_bounds_max": [
        2.4482002787456008,
        5.722924029505417,
        3.071421806396714
      ]
    },
    "idle2": {
      "phase": 2,
      "loop": true,
      "start_frame": 1,
      "end_frame": 27,
      "duration_seconds": 1.0833333333333333,
      "file": "models/phase_2.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -3.179084522687929,
        -0.12916740151446396,
        -1.1002969605072463
      ],
      "sampled_bounds_max": [
        3.0924121338602633,
        6.917069947397873,
        0.9868012759369725
      ]
    },
    "search2": {
      "phase": 2,
      "loop": true,
      "start_frame": 1,
      "end_frame": 27,
      "duration_seconds": 1.0833333333333333,
      "file": "models/phase_2.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -4.11733898388577,
        -0.1236162391946003,
        -1.4398919764574387
      ],
      "sampled_bounds_max": [
        2.3332493566250028,
        5.11101916996257,
        2.8802703968719108
      ]
    },
    "walk2": {
      "phase": 2,
      "loop": true,
      "start_frame": 1,
      "end_frame": 31,
      "duration_seconds": 1.25,
      "file": "models/phase_2.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -4.376217174410666,
        -0.234486964227838,
        -1.5678264241171807
      ],
      "sampled_bounds_max": [
        2.94091369458919,
        4.859768187678024,
        3.0868166900423795
      ]
    },
    "chase3": {
      "phase": 3,
      "loop": true,
      "start_frame": 1,
      "end_frame": 31,
      "duration_seconds": 1.25,
      "file": "models/phase_3.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -4.662925859998635,
        0.0942812443812091,
        -3.378138372605571
      ],
      "sampled_bounds_max": [
        3.699005938544987,
        4.773556705809953,
        2.519143194154556
      ]
    },
    "idle3": {
      "phase": 3,
      "loop": true,
      "start_frame": 1,
      "end_frame": 31,
      "duration_seconds": 1.25,
      "file": "models/phase_3.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -2.916374292325861,
        0.018062957887758913,
        -1.870476074357292
      ],
      "sampled_bounds_max": [
        3.059996214905752,
        4.746599193908097,
        2.319017938972276
      ]
    },
    "jumpscare3": {
      "phase": 3,
      "loop": false,
      "start_frame": 1,
      "end_frame": 24,
      "duration_seconds": 0.9583333333333334,
      "file": "models/phase_3.glb",
      "root_motion": "authored motion baked into skeleton; wrapper movement controlled by game",
      "sampled_bounds_min": [
        -2.916374292325861,
        -0.06857807562881657,
        -1.8612739690364755
      ],
      "sampled_bounds_max": [
        3.1963615630601123,
        7.298908910108734,
        5.103988538996289
      ]
    }
  },
  "coordinate_system": "Godot Y up, monster faces +Z; source Blender -Y forward",
  "baking": "Standard skeleton animation plus corrective blend shapes for procedural surface deformation. 24 fps.",
  "runtime_bones": 25,
  "core_deformation_bones": 24,
  "head_deformation": "Additional transform bone preserves head shear and squash/stretch with standard glTF transforms."
}
