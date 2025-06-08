import json
from fastapi import FastAPI
from langchain_app.loader import load_processed_scholarship_documents
from langchain_app.embedder import store_embeddings
from langchain_app.retriever import get_retriever
from langchain_app.chain import get_qa_chain
from utils.uesrInput_format import format_user_input_as_query
from models.user_input import UserInput

# 최초 실행 시 한번만 실행
'''docs = load_processed_scholarship_documents("data/scholarship_new_processed.json")
store_embeddings(docs, persist_directory="chroma_db")'''
retriever = get_retriever()
rag_chain = get_qa_chain()

app = FastAPI()

@app.post("/recommend")
def recommend(user_input: UserInput):
    formatted_user_input = format_user_input_as_query(user_input)
    relevant_docs = retriever.invoke(formatted_user_input)
    print("🔍 검색된 문서 수:", len(relevant_docs)) 
    
    # JSON string → dict로 변환
    input_documents = []
    for doc in relevant_docs:
        print("📄 문서 내용 일부:", doc.page_content[:100])
        try:
            content = doc.page_content.strip()
            if content.startswith("{") and content.endswith("}"):
                parsed = json.loads(content)
                input_documents.append(parsed)
        except Exception as e:
            print("❌ 문서 파싱 실패:", e)

    # raw 리스트 그대로 넘김 (dump 하지 않음)
    inputs = user_input.dict() | {
        "input_documents": json.dumps(input_documents, ensure_ascii=False, indent=2),
        "formatted_user_input": formatted_user_input
    }
    result = rag_chain.invoke(inputs)

    gpt_output = result["input_documents"]
    print("🧠 GPT 출력 원본:\n", gpt_output)
    print("▶️ gpt_output 타입:", type(gpt_output))
    
    if isinstance(gpt_output, str):
        try:
            recommendations = json.loads(gpt_output)
        except json.JSONDecodeError:
            return {"error": "GPT 응답이 유효한 JSON 형식이 아닙니다.", "raw_output": gpt_output}
    else:
        recommendations = gpt_output

  # 👉 후처리: scholarship_id만 추출
    id_list = []
    for item in recommendations:
        if isinstance(item, dict) and "scholarship_id" in item:
            try:
                id_list.append(int(item["scholarship_id"]))
            except ValueError:
                continue  # 정수 변환 실패 시 무시

    return {"recommendations": id_list}

