import { ThoughtCategory } from '@/types/Thought';

interface AIReframingOptions {
  thoughtText: string;
  category: ThoughtCategory;
  emotionIntensity: number;
  userContext?: string;
  personalizedTriggers?: string[];
}

interface ReframingResponse {
  reframedThought: string;
  cognitiveDistortions: string[];
  techniques: string[];
  alternativePerspectives: string[];
  actionableSteps: string[];
  confidenceScore: number;
}

class FreeAIReframingService {
  private currentProvider = 'local'; // 기본은 로컬 시스템

  async reframeThought(options: AIReframingOptions): Promise<ReframingResponse> {
    // 🆓 100% 무료 AI 서비스들을 순서대로 시도
    const freeProviders = [
      () => this.useHuggingFaceFree(options),    // 1순위: Hugging Face 무료
      () => this.useOllamaLocal(options),        // 2순위: 로컬 Ollama  
      () => this.useAdvancedLocalAI(options),    // 3순위: 고급 로컬 AI
    ];

    for (const provider of freeProviders) {
      try {
        const result = await provider();
        if (result && result.reframedThought.length > 10) {
          return result;
        }
      } catch (error) {
        console.warn('무료 AI 서비스 시도 실패, 다음 옵션 시도:', error);
        continue;
      }
    }

    // 모든 AI 실패 시 최종 백업 (항상 작동)
    return this.getGuaranteedLocalReframing(options);
  }

  // 🤗 Hugging Face 완전 무료 (무제한)
  private async useHuggingFaceFree(options: AIReframingOptions): Promise<ReframingResponse | null> {
    try {
      // 무료 모델들 (API 키 불필요)
      const freeModels = [
        'microsoft/DialoGPT-large',
        'facebook/blenderbot-400M-distill',
        'microsoft/DialoGPT-medium'
      ];

      for (const model of freeModels) {
        try {
          const response = await fetch(`https://api-inference.huggingface.co/models/${model}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              inputs: this.buildSimplePrompt(options),
              parameters: {
                max_length: 150,
                temperature: 0.7,
                do_sample: true,
              }
            }),
          });

          if (response.ok) {
            const data = await response.json();
            if (data.generated_text || (Array.isArray(data) && data[0]?.generated_text)) {
              const text = data.generated_text || data[0]?.generated_text;
              return this.parseSimpleResponse(text, options);
            }
          }
        } catch (modelError) {
          console.warn(`모델 ${model} 실패, 다음 모델 시도`, modelError);
          continue;
        }
      }
    } catch (error) {
      console.warn('Hugging Face 무료 API 실패:', error);
    }
    return null;
  }

  // 🏠 Ollama 로컬 (완전 무료, 무제한)
  private async useOllamaLocal(options: AIReframingOptions): Promise<ReframingResponse | null> {
    try {
      const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'llama2', // 또는 'mistral', 'codellama', 'neural-chat'
          prompt: this.buildCBTPrompt(options),
          stream: false,
          options: {
            temperature: 0.7,
            top_k: 40,
            top_p: 0.9,
          }
        }),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.response) {
          return this.parseAIResponse(data.response);
        }
      }
    } catch (error) {
      console.warn('Ollama 로컬 API 실패 (설치 안됨):', error);
    }
    return null;
  }

  // 🧠 고급 로컬 AI 시스템 (CBT 전문 알고리즘)
  private useAdvancedLocalAI(options: AIReframingOptions): Promise<ReframingResponse> {
    return Promise.resolve(this.getAdvancedLocalReframing(options));
  }

  // 💯 보장된 로컬 리프레이밍 (항상 작동)
  private getGuaranteedLocalReframing(options: AIReframingOptions): ReframingResponse {
    const patterns = this.identifyAdvancedCognitiveDistortions(options.thoughtText);
    const reframed = this.generateProfessionalReframe(options, patterns);
    
    return {
      reframedThought: reframed,
      cognitiveDistortions: patterns,
      techniques: this.selectOptimalTechniques(options.category, patterns),
      alternativePerspectives: this.generateDeepAlternatives(options),
      actionableSteps: this.generatePersonalizedSteps(options),
      confidenceScore: 8, // 고도화된 로컬 시스템
    };
  }

  // 🎯 상황별 맞춤 리프레이밍 (핵심 추가!)
  private generateSituationSpecificReframe(options: AIReframingOptions): string | null {
    const text = options.thoughtText.toLowerCase();
    
    // 연애/관계 관련
    if (text.includes('여자친구') || text.includes('남자친구') || text.includes('애인') || text.includes('롱디') || text.includes('장거리')) {
      if (text.includes('해외') || text.includes('멀리') || text.includes('떠나') || text.includes('롱디')) {
        return `여자친구가 해외로 떠나는 것 때문에 마음이 아프시는군요. 이런 슬픔을 느끼는 것은 당연해요 - 소중한 사람과 떨어져 있게 되니까요. 하지만 장거리 연애도 관계를 더 깊게 만들 수 있는 기회가 될 수 있어요. 서로에 대한 그리움이 사랑을 더 소중하게 만들고, 만날 때의 기쁨도 더 클 거예요. 요즘은 영상통화, 메시지로 언제든 소통할 수 있고, 각자의 성장 시간도 가질 수 있어요. 힘들겠지만 두 분의 사랑이 거리를 이겨낼 수 있을 거예요.`;
      }
    }
    
    // 취업/직장 관련
    if (text.includes('면접') || text.includes('취업') || text.includes('회사') || text.includes('직장')) {
      if (text.includes('떨어') || text.includes('실패') || text.includes('불합격')) {
        return `취업이나 면접에서 좋은 결과를 얻지 못해서 속상하시겠어요. 하지만 이것이 당신의 가치나 능력을 평가하는 것은 아니에요. 채용은 정말 많은 변수가 있고, 때로는 운이나 타이밍의 문제이기도 해요. 이번 경험을 통해 면접 스킬을 늘렸고, 다음에는 더 잘할 수 있을 거예요.`;
      }
    }
    
    // 학업/시험 관련  
    if (text.includes('시험') || text.includes('성적') || text.includes('공부')) {
      if (text.includes('망했') || text.includes('못했') || text.includes('떨어')) {
        return `시험이나 공부에서 원하는 결과를 얻지 못해서 실망스러우시겠어요. 하지만 한 번의 시험 결과가 당신의 모든 것을 결정하지는 않아요. 실패도 배움의 과정이고, 이를 통해 부족한 부분을 파악할 수 있게 되었어요.`;
      }
    }
    
    return null; // 특별한 상황이 아니면 일반 템플릿 사용
  }

  // 🎯 실용적이고 맞춤형 리프레이밍 생성
  private generateProfessionalReframe(options: AIReframingOptions, patterns: string[]): string {
    // 먼저 상황별 맞춤 템플릿 체크
    const situationBasedResponse = this.generateSituationSpecificReframe(options);
    if (situationBasedResponse) {
      return situationBasedResponse;
    }

    const professionalTemplates = {
      '파국화': [
        `"${options.thoughtText}"라는 생각이 드시는군요. 하지만 잠깐, 이 상황이 정말 돌이킬 수 없는 재앙일까요? 지금까지 수많은 어려움을 헤쳐나온 당신의 회복력을 생각해보세요. 이번 일도 분명 극복할 수 있는 도전 중 하나일 것입니다.`,
        `현재 상황을 재평가해보면: 어려운 상황이지만 최악은 아닙니다. 이런 경험을 통해 더 강해질 수 있고, 앞으로 비슷한 상황에서 더 잘 대처할 수 있게 될 거예요.`,
        `"${options.thoughtText}"의 감정을 이해합니다. 하지만 이 순간의 어려움이 영원하지 않다는 것을 기억해주세요. 시간이 지나면서 상황은 변하고, 당신도 이를 통해 성장할 것입니다.`
      ],
      
      '전부 아니면 전무 사고': [
        `"${options.thoughtText}"에서 '항상', '절대', '모든' 같은 표현이 보이네요. 실제로는 완전히 흑백으로 나뉘는 일은 드물어요. 회색지대도 있고, 부분적인 성공도 있습니다. 완벽하지 않아도 충분히 의미있는 성과일 수 있어요.`,
        `모든 것이 완벽하거나 완전히 실패하는 것은 아닙니다. 작은 진전도 소중한 성장이고, 부분적인 성공도 가치가 있습니다. 중간 단계의 성취를 인정해주세요.`,
        `흑백논리에서 벗어나 보면: 이 상황에서도 긍정적인 면이 있고, 배울 점이 있습니다. 완벽하지 않다고 해서 무가치한 것은 아니에요.`
      ],
      
      '자기비난': [
        `자신을 너무 혹독하게 대하고 계시네요. 만약 가장 친한 친구가 같은 상황에서 고민한다면 뭐라고 말해주실까요? 분명 따뜻하고 이해심 있게 격려해주실 텐데, 자신에게도 그런 친절함을 베풀어주세요.`,
        `실수는 인간다운 것이고, 성장의 기회입니다. "${options.thoughtText}"라고 자책하시지만, 이 경험을 통해 더 나은 선택을 할 수 있게 될 거예요. 자신을 용서하고 배움에 집중해보세요.`,
        `모든 책임을 자신에게 돌리지 마세요. 상황에는 여러 요인이 작용합니다. 당신이 통제할 수 있는 부분에만 집중하고, 할 수 없는 부분은 받아들이는 지혜를 가져보세요.`
      ],
      
      '부정적 예측': [
        `"${options.thoughtText}"라고 미래를 예측하고 계시는군요. 하지만 미래는 아직 일어나지 않았어요. 과거에도 걱정했던 일들이 실제로는 생각보다 나았던 경험이 있지 않나요? 현재에 집중하고, 할 수 있는 최선을 다해보세요.`,
        `부정적인 결과만 예상하지 말고, 긍정적인 가능성도 열어두세요. 당신의 노력과 능력을 믿고, 좋은 결과를 위해 할 수 있는 일들에 집중해보세요.`,
        `미래에 대한 불안보다는 현재 할 수 있는 행동에 집중해보세요. 작은 행동들이 모여서 긍정적인 변화를 만들어낼 수 있습니다.`
      ],
      
      '일반화': [
        `한 번의 경험이 모든 것을 결정하지 않아요. "${options.thoughtText}"라고 생각하시지만, 과거에 성공했던 경험들도 분명 있을 거예요. 이번 일은 이번 일일 뿐, 당신의 모든 능력을 판단하는 기준이 아닙니다.`,
        `이 한 가지 상황으로 전체를 판단하지 마세요. 당신에게는 다양한 면이 있고, 많은 가능성이 있습니다. 이전의 성과와 강점들을 떠올려보세요.`,
        `하나의 패턴으로만 보지 말고, 더 넓은 관점에서 생각해보세요. 변화와 성장의 여지는 항상 있고, 새로운 시도를 통해 다른 결과를 만들어낼 수 있어요.`
      ]
    };

    // 감지된 패턴 중 가장 강한 패턴의 템플릿 사용
    for (const pattern of patterns) {
      if (professionalTemplates[pattern as keyof typeof professionalTemplates]) {
        const patternTemplates = professionalTemplates[pattern as keyof typeof professionalTemplates];
        return patternTemplates[Math.floor(Math.random() * patternTemplates.length)];
      }
    }

    // 감정 강도별 맞춤 응답
    if (options.emotionIntensity >= 8) {
      return `지금 정말 힘드신 것 같아요. "${options.thoughtText}"라는 생각이 마음을 무겁게 하고 있겠지만, 이 어려운 시간도 지나갈 거예요. 지금은 자신을 돌보는 것이 가장 중요해요. 천천히 숨을 쉬고, 당신을 지지해주는 사람들을 떠올려보세요. 당신은 혼자가 아니고, 이 상황을 극복할 힘이 있어요.`;
    } else if (options.emotionIntensity >= 6) {
      return `"${options.thoughtText}"라는 생각으로 마음이 편하지 않으시군요. 이런 감정을 느끼는 것은 자연스러운 일이에요. 하지만 이 생각이 현실의 전부는 아니라는 것을 기억해주세요. 다른 관점에서 보면 상황이 다르게 느껴질 수 있고, 시간이 지나면서 새로운 해결책도 보일 거예요.`;
    } else {
      return `"${options.thoughtText}"라는 생각을 다른 각도에서 살펴보면: 이 상황에서도 배울 점이 있고, 성장할 수 있는 기회가 될 수 있어요. 현재의 어려움이 영원하지 않다는 것을 기억하고, 작은 긍정적인 변화들에도 관심을 가져보세요.`;
    }
  }

  // 🔍 고급 인지왜곡 감지
  private identifyAdvancedCognitiveDistortions(text: string): string[] {
    const distortions = [];
    const lowerText = text.toLowerCase();

    // 더 정교한 패턴 매칭
    const patterns = {
      '전부 아니면 전무 사고': /항상|절대|모든|전혀|완전히|전부|never|always|completely|totally|entirely/i,
      '파국화': /끔찍|재앙|망했|죽겠|최악|terrible|awful|catastrophe|disaster|horrible|ruined/i,
      '자기비난': /내 탓|나 때문|내가 잘못|바보|멍청|my fault|because of me|stupid|idiot/i,
      '부정적 예측': /못해|할 수 없어|불가능|실패할|안 될|can't|impossible|unable|will fail|won't work/i,
      '일반화': /또|또다시|매번|역시|늘|언제나|always happens|every time|typical/i,
      '마음읽기': /생각할 거야|느낄 거야|판단할|thinks|feels|judges/i,
      '감정적 추론': /느끼니까|기분이|감정이|feel like|because I feel/i,
      '개인화': /내 책임|나 때문에|because of me|my responsibility/i
    };

    for (const [distortion, pattern] of Object.entries(patterns)) {
      if (pattern.test(text)) {
        distortions.push(distortion);
      }
    }

    return distortions;
  }

  // 🎯 최적 기법 선택
  private selectOptimalTechniques(category: ThoughtCategory, distortions: string[]): string[] {
    const baseTechniques = ['현실 확인', '관점 전환', '감정 인식'];
    
    // 인지왜곡별 특화 기법
    const specialTechniques: { [key: string]: string[] } = {
      '파국화': ['최악/최선/현실적 시나리오', '확률적 사고', '과거 경험 회상'],
      '전부 아니면 전무 사고': ['회색지대 찾기', '부분적 성공 인정', '연속체 사고'],
      '자기비난': ['자기 친구 되기', '책임 분산하기', '실수의 정상성'],
      '부정적 예측': ['증거 찾기', '행동 실험', '현재 집중'],
      '일반화': ['예외 찾기', '패턴 분석', '다양성 인정']
    };

    distortions.forEach(distortion => {
      if (specialTechniques[distortion]) {
        baseTechniques.push(...specialTechniques[distortion]);
      }
    });

    return [...new Set(baseTechniques)]; // 중복 제거
  }

  // 🤔 깊이 있는 대안적 관점
  private generateDeepAlternatives(options: AIReframingOptions): string[] {
    const categoryAlternatives = {
      'work': [
        '이 업무 경험이 나의 전문성과 문제해결 능력을 어떻게 향상시킬 수 있을까?',
        '동료들도 비슷한 도전을 겪었을 텐데, 그들은 어떻게 극복했을까?',
        '이 프로젝트에서 얻은 교훈을 다음 기회에 어떻게 활용할 수 있을까?',
        '완벽하지 않더라도 내가 기여한 가치있는 부분들은 무엇일까?'
      ],
      'relationships': [
        '상대방도 자신만의 어려움과 관점을 가지고 있을 텐데, 그것은 어떨까?',
        '이 갈등을 통해 서로를 더 깊이 이해할 수 있는 기회가 될 수 없을까?',
        '건강한 관계에는 때로 어려운 대화와 성장통이 필요하지 않을까?',
        '이 상황이 관계를 더욱 단단하게 만드는 계기가 될 수 있을까?'
      ],
      'personal': [
        '이 경험이 나를 더 성숙하고 지혜롭게 만들어줄 수 있을까?',
        '미래의 내가 지금의 나에게 해주고 싶은 격려의 말은 무엇일까?',
        '지금까지 극복해온 수많은 어려움들을 생각해보면 어떨까?',
        '이 도전이 나의 숨겨진 강점을 발견하는 기회가 될 수 있을까?'
      ],
      'health': [
        '몸과 마음이 나에게 전달하려는 메시지는 무엇일까?',
        '이 경험을 통해 자기 돌봄의 중요성을 더 깨달을 수 있을까?',
        '작은 건강한 선택들이 모여서 큰 변화를 만들 수 있지 않을까?',
        '완벽한 건강보다는 점진적인 개선에 집중하면 어떨까?'
      ]
    };

    const baseAlternatives = [
      '이 상황에서 내가 통제할 수 있는 부분은 무엇이고, 받아들여야 할 부분은 무엇일까?',
      '6개월 후, 1년 후에는 이 경험이 어떤 의미로 남아있을까?',
      '이 어려움이 나에게 가르쳐주는 중요한 인생 교훈은 무엇일까?',
      '만약 이 상황을 책이나 영화로 본다면, 주인공이 어떻게 성장할까?'
    ];

    const categorySpecific = categoryAlternatives[options.category as keyof typeof categoryAlternatives] || [];
    return [...baseAlternatives, ...categorySpecific];
  }

  // 🎯 개인맞춤 실행 단계
  private generatePersonalizedSteps(options: AIReframingOptions): string[] {
    const intensityBasedSteps = {
      high: [ // 8-10점
        '지금 이 순간 안전한 곳에 있다는 것을 확인하기',
        '4-7-8 호흡법으로 마음 진정시키기 (4초 들이쉬고, 7초 멈추고, 8초 내쉬기)',
        '신뢰할 수 있는 사람에게 연락하여 지지받기',
        '전문가의 도움 받는 것 고려해보기'
      ],
      medium: [ // 5-7점
        '깊게 3번 호흡하며 현재 순간에 집중하기',
        '이 감정이 일시적이라는 것을 스스로에게 상기시키기',
        '작고 구체적인 한 가지 행동 계획 세우기',
        '자신을 격려하는 긍정적인 문장 말해보기'
      ],
      low: [ // 1-4점
        '현재 상황에서 감사할 수 있는 3가지 찾아보기',
        '이 경험에서 배울 수 있는 교훈 적어보기',
        '다음 단계를 위한 구체적인 계획 수립하기',
        '자신의 성장과 발전에 집중하기'
      ]
    };

    const categorySteps = {
      'work': [
        '업무 우선순위 다시 정리하기',
        '동료나 상사와 솔직한 대화 나누기',
        '전문성 개발을 위한 학습 계획 세우기'
      ],
      'relationships': [
        '상대방의 관점에서 상황 이해해보기',
        '진솔한 대화를 위한 시간과 장소 마련하기',
        '관계 개선을 위한 작은 행동 실천하기'
      ],
      'personal': [
        '자기 돌봄 활동 하나 선택해서 실행하기',
        '개인적 성장 목표 설정하기',
        '자신의 강점과 성취 목록 작성하기'
      ],
      'health': [
        '오늘 할 수 있는 건강한 선택 하나 실천하기',
        '충분한 수면과 영양 섭취 계획하기',
        '필요시 전문의 상담 받기'
      ]
    };

    let steps = [];
    
    // 감정 강도별 단계
    if (options.emotionIntensity >= 8) {
      steps.push(...intensityBasedSteps.high);
    } else if (options.emotionIntensity >= 5) {
      steps.push(...intensityBasedSteps.medium);
    } else {
      steps.push(...intensityBasedSteps.low);
    }

    // 카테고리별 단계 추가
    const categorySpecific = categorySteps[options.category as keyof typeof categorySteps] || [];
    steps.push(...categorySpecific);

    return steps.slice(0, 4); // 최대 4개 단계
  }

  // 간단한 프롬프트 생성 (Hugging Face용)
  private buildSimplePrompt(options: AIReframingOptions): string {
    return `Help me reframe this negative thought: "${options.thoughtText}". I'm feeling ${options.emotionIntensity}/10 intensity. Give me a more balanced perspective.`;
  }

  // CBT 전문 프롬프트 생성 (Ollama용)
  private buildCBTPrompt(options: AIReframingOptions): string {
    return `You are a cognitive behavioral therapy expert. Help me reframe this negative thought using CBT techniques:

Thought: "${options.thoughtText}"
Category: ${options.category}
Emotion intensity: ${options.emotionIntensity}/10

Please provide:
1. A reframed, balanced perspective
2. Identified cognitive distortions
3. CBT techniques used
4. Alternative viewpoints
5. Actionable steps

Keep the response supportive and professional.`;
  }

  // 단순 응답 파싱
  private parseSimpleResponse(text: string, options: AIReframingOptions): ReframingResponse {
    return {
      reframedThought: text.trim() || this.generateProfessionalReframe(options, []),
      cognitiveDistortions: this.identifyAdvancedCognitiveDistortions(options.thoughtText),
      techniques: ['AI 지원 리프레이밍', '관점 전환'],
      alternativePerspectives: this.generateDeepAlternatives(options),
      actionableSteps: this.generatePersonalizedSteps(options),
      confidenceScore: 7,
    };
  }

  // AI 응답 파싱 (구조화된 응답용)
  private parseAIResponse(content: string): ReframingResponse {
    return {
      reframedThought: this.extractSection(content, 'reframed') || this.extractSection(content, 'balanced') || content.substring(0, 200),
      cognitiveDistortions: this.extractListItems(content, 'distortion') || ['AI 분석 결과'],
      techniques: this.extractListItems(content, 'technique') || ['AI 지원 CBT'],
      alternativePerspectives: this.extractListItems(content, 'alternative') || ['AI 제안 관점'],
      actionableSteps: this.extractListItems(content, 'action') || ['AI 권장 단계'],
      confidenceScore: 8,
    };
  }

  private extractSection(content: string, keyword: string): string {
    const regex = new RegExp(`${keyword}[^\\n]*:?\\s*([^\\n]+)`, 'i');
    const match = content.match(regex);
    return match ? match[1].trim() : '';
  }

  private extractListItems(content: string, keyword: string): string[] {
    const lines = content.split('\n');
    const items: string[] = [];
    let capturing = false;
    
    for (const line of lines) {
      if (line.toLowerCase().includes(keyword)) {
        capturing = true;
        continue;
      }
      if (capturing && line.trim().startsWith('-')) {
        items.push(line.replace(/^-\s*/, '').trim());
      } else if (capturing && line.trim() === '') {
        continue;
      } else if (capturing) {
        break;
      }
    }
    
    return items;
  }

  private getAdvancedLocalReframing(options: AIReframingOptions): ReframingResponse {
    return this.getGuaranteedLocalReframing(options);
  }
}

export const aiReframingService = new FreeAIReframingService(); 