#!/bin/bash


cat >> target/linux/mediatek/image/filogic.mk <<EOF

&partitions {
	partition@580000 {
		label = "ubi";
		reg = <0x580000 0x7a80000>;
	};
};
EOF
