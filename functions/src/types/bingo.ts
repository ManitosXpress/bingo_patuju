export interface BingoRound {
  id: string;
  name: string;
  patterns: string[];
  isCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface BingoGame {
  id: string;
  name: string;
  date: string;
  rounds: BingoRound[];
  totalCartillas: number;
  createdAt: Date;
  updatedAt: Date;
  isCompleted: boolean;
}

export interface CreateBingoGameRequest {
  name: string;
  date: string;
  rounds: Omit<BingoRound, 'id' | 'createdAt' | 'updatedAt'>[];
  totalCartillas: number;
}

export interface UpdateBingoGameRequest {
  name?: string;
  date?: string;
  rounds?: BingoRound[];
  totalCartillas?: number;
  isCompleted?: boolean;
}

export interface CreateRoundRequest {
  name: string;
  patterns: string[];
  isCompleted?: boolean;
}

export interface UpdateRoundRequest {
  name?: string;
  patterns?: string[];
  isCompleted?: boolean;
}
