rmdir /s /q sim
if not exist sim\ mkdir sim
vsim -do sim_vic20.do
