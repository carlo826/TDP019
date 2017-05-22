@ int global = 5;

def int five_times(){
	for (int i = 0; (i < 10); i++){
		if (i == global){
			print("Goodbye world!");
			return ;
		}
		else{
			print("Hello world!");
		};

	};

};

five_times()