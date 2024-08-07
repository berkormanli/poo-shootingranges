Config = {
    HeadShotPoint = 5,
    BodyShotPoint = 2,
}

Config.ShootingrangeIntId = {
    [137729] = true,
    [248065] = true
}

Config.UpperRows = {
    [137729] = {
        [1] = {
            startPoint = vector3(28.65, -1073.123, 29.5),
            endPoint = vector3(17.47, -1069.05, 29.5)
        },
        [2] = {
            startPoint = vector3(24.84, -1083.520, 29.5),
            endPoint = vector3(13.68, -1079.46, 29.5)
        },
        [3] = {
            startPoint = vector3(21.7, -1092.1, 29.5),
            endPoint = vector3(10.575, -1088.04, 29.5)
        }
    },
    [248065] = {
        [1] = {
            startPoint = vector3(815.63, -2191.556, 29.5),
            endPoint = vector3(827.466, -2191.556, 29.5)
        },
        [2] = {
            startPoint = vector3(815.613, -2180.471, 29.5),
            endPoint = vector3(827.466, -2180.471, 29.5)
        },
        [3] = {
            startPoint = vector3(815.639, -2171.37, 29.5),
            endPoint = vector3(827.462, -2171.369, 29.5)
        }
    }
}

Config.LowerRows = {
    [137729] = {
        [1] = {
            vector3(15.41565227508545, -1079.7486572265625, 28.79701805114746),
            vector3(16.7424144744873, -1080.2623291015625, 28.79701805114746),
            vector3(20.96516418457031, -1081.78125, 28.79701805114746),
            vector3(22.48353958129882, -1082.335205078125, 28.79701805114746)
        },
        [2] = {
            vector3(19.73405456542968, -1091.1063232421875, 28.79701805114746),
            vector3(21.18715476989746, -1091.61572265625, 28.79701805114746)
        }
    },
    [248065] = {
        [1] = {
            vector3(818.3853149414062, -2180.796875, 28.67863082885742),
            vector3(819.8010864257812, -2180.796875, 28.67863082885742),
            vector3(824.3314208984375, -2180.796875, 28.67863082885742),
            vector3(825.8914184570312, -2180.796875, 28.67863082885742)
        },
        [2] = {
            vector3(816.049072265625, -2171.680419921875, 28.67863082885742),
            vector3(817.7649536132812, -2171.680419921875, 28.67863082885742)
        }
    }
}

Config.TargetRotations = {
    [137729] = {
        [`prop_range_target_01`] = {
            spawnRotation = vector3(90.0, 0, -20.0),
            openRotation = vector3(0.0, 0.0, -20.0),
            closeRotation = vector3(90.0, 0.0, -20.0)
        },
        [`gr_prop_gr_target_05b`] = {
            spawnRotation = vector3(-90.0, 0, -20.0),
            openRotation = vector3(0.0, 0.0, -20.0),
            closeRotation = vector3(-90.0, 0.0, -20.0)
        }
    },
    [248065] = {
        [`prop_range_target_01`] = {
            spawnRotation = vector3(-90.0, 0, 0.0),
            openRotation = vector3(0.0, 0.0, 0.0),
            closeRotation = vector3(-90.0, 0.0, 0.0)
        },
        [`gr_prop_gr_target_05b`] = {
            spawnRotation = vector3(90.0, 0, 0.0),
            openRotation = vector3(0.0, 0.0, 0.0),
            closeRotation = vector3(90.0, 0.0, 0.0)
        }
    }
}

Config.TargetOffsets = {
    [`prop_range_target_01`] = {
        headOffset = {
            x = {
                min = -0.12,
                max = 0.12
            },
            z = {
                min = -0.76,
                max = -0.55
            }
        },
        bodyOffset = {
            x = {
                min = -0.32,
                max = 0.32
            },
            z = {
                min = -1.72,
                max = -0.76,
            }
        }
    },
    [`gr_prop_gr_target_05b`] = {
        headOffset = {
            z = {
                min = 1.15,
                max = 1.4
            }
        },
        bodyOffset = {
            z = {
                min = 0.45,
                max = 1.15,
            }
        }
    }
}

Config.TargetConfig = {
    [137729] = {
        coords = vec3(13.65, -1097.15, 29.5),
        size = vec3(3.5, 1.0, 0.75),
        heading = 340.0,
        debug = false
    },
    [248065] = {
        coords = vec3(821.4954, -2163.8320, 29.5),
        size = vec3(3.5, 1.0, 0.75),
        heading = 0.0,
        debug = false
    },
}

Config.ZoneConfig = {
    [137729] = {
        coords = vec3(13.1, -1098.35, 30.0),
        size = vec3(13.0, 3.4, 3),
        heading = 340.0,
        debug = false
    },
    [248065] = {
        coords = vec3(821.5388, -2162.2102, 29.5),
        size = vec3(13.0, 3.4, 3),
        heading = 0.0,
        debug = false
    },
}

Config.TrainingModes = {
    [137729] = {
        {
            mode = "timetrial",
            timetrialTime = 15.0,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 20.0,
            targetOptions = {
                distance = 1.5,
                label = "Time Trial",
                icon = 'fa-solid fa-clock',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        },
        {
            mode = "pointrush",
            pointGoal = 20,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 20.0,
            targetOptions = {
                distance = 1.5,
                label = "Point Rush",
                icon = 'fa-solid fa-chart-simple',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        },
        {
            mode = "targethunt",
            targetGoal = 1,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 100.0,
            targetOptions = {
                distance = 1.5,
                label = "Target Hunt",
                icon = 'fa-solid fa-bullseye',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        }
    },
    [248065] = {
        {
            mode = "timetrial",
            timetrialTime = 60.0,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 20.0,
            targetOptions = {
                distance = 1.5,
                label = "Time Trial",-- Lang:t('target.timetrial'),
                icon = 'fa-solid fa-clock',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        },
        {
            mode = "pointrush",
            pointGoal = 50,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 20.0,
            targetOptions = {
                distance = 1.5,
                label = "Point Rush",-- Lang:t('target.pointrush'),
                icon = 'fa-solid fa-chart-simple',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        },
        {
            mode = "targethunt",
            targetGoal = 1,
            upperRowModel = `prop_range_target_01`,
            upperRows = {
                [1] = {
                    active = true,
                    canMove = true
                },
                [2] = {
                    active = true,
                    canMove = true
                },
                [3] = {
                    active = true,
                    canMove = true
                }
            },
            lowerRowModel = `gr_prop_gr_target_05b`,
            lowerRows = {
                [1] = {
                    active = true,
                    canMove = false
                },
                [2] = {
                    active = true,
                    canMove = false
                },
            },
            movingChance = 20.0,
            targetOptions = {
                distance = 1.5,
                label = "Target Hunt",-- Lang:t('target.targethunt'),
                icon = 'fa-solid fa-bullseye',
                onSelect = function(data)
                    TriggerServerEvent('pc-shootingranges:server:setStoreState:isSessionInProgress', data.interiorId, true)
                    StartSession(data.sessionMode, data.sessionOptions)
                end
            }
        }
    },
}