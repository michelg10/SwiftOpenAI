//
//  AIProxyService.swift
//
//
//  Created by Lou Zell on 3/27/24.
//

import Foundation

struct AIProxyService: OpenAIService {

   let session: URLSession
   let decoder: JSONDecoder
   var deviceCheckBypass: String?

   private let sessionID = UUID().uuidString

   /// Your partial key is provided during the integration process at dashboard.aiproxy.pro
   /// Please see the [integration guide](https://www.aiproxy.pro/docs/integration-guide.html) for aquiring your partial key
   private let partialKey: String

   /// [organization](https://platform.openai.com/docs/api-reference/organization-optional)
   private let organizationID: String?

   private static let assistantsBeta = "assistants=v1"

   init(
      partialKey: String,
      organizationID: String? = nil,
      configuration: URLSessionConfiguration = .default,
      decoder: JSONDecoder = .init())
   {
      self.session = URLSession(configuration: configuration)
      self.decoder = decoder
      self.partialKey = partialKey
      self.organizationID = organizationID
   }

   // MARK: Audio

   func createTranscription(
      parameters: AudioTranscriptionParameters)
      async throws -> AudioObject
   {
       let request = try await OpenAIAPI.audio(.transcriptions).multiPartRequest(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post,  params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AudioObject.self, with: request)
   }

   func createTranslation(
      parameters: AudioTranslationParameters)
      async throws -> AudioObject
   {
      let request = try await OpenAIAPI.audio(.translations).multiPartRequest(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AudioObject.self, with: request)
   }

   func createSpeech(
      parameters: AudioSpeechParameters)
      async throws -> AudioSpeechObject
   {
      let request = try await OpenAIAPI.audio(.speech).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      let data = try await fetchAudio(with: request)
      return AudioSpeechObject(output: data)
   }

   // MARK: Chat

   func startChat(
      parameters: ChatCompletionParameters)
      async throws -> ChatCompletionObject
   {
      var chatParameters = parameters
      chatParameters.stream = false
      let request = try await OpenAIAPI.chat.request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: chatParameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ChatCompletionObject.self, with: request)
   }

   func startStreamedChat(
      parameters: ChatCompletionParameters)
      async throws -> AsyncThrowingStream<ChatCompletionChunkObject, Error>
   {
      var chatParameters = parameters
      chatParameters.stream = true
      let request = try await OpenAIAPI.chat.request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: chatParameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetchStream(type: ChatCompletionChunkObject.self, with: request)
   }

   // MARK: Embeddings

   func createEmbeddings(
      parameters: EmbeddingParameter)
      async throws -> OpenAIResponse<EmbeddingObject>
   {
      let request = try await OpenAIAPI.embeddings.request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<EmbeddingObject>.self, with: request)
   }

   // MARK: Fine-tuning

   func createFineTuningJob(
      parameters: FineTuningJobParameters)
      async throws -> FineTuningJobObject
   {
      let request = try await OpenAIAPI.fineTuning(.create).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FineTuningJobObject.self, with: request)
   }

   func listFineTuningJobs(
      after lastJobID: String? = nil,
      limit: Int? = nil)
      async throws -> OpenAIResponse<FineTuningJobObject>
   {
      var queryItems: [URLQueryItem] = []
      if let lastJobID, let limit {
         queryItems = [.init(name: "after", value: lastJobID), .init(name: "limit", value: "\(limit)")]
      } else if let lastJobID {
         queryItems = [.init(name: "after", value: lastJobID)]
      } else if let limit {
         queryItems = [.init(name: "limit", value: "\(limit)")]
      }

      let request = try await OpenAIAPI.fineTuning(.list).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<FineTuningJobObject>.self, with: request)
   }

   func retrieveFineTuningJob(
      id: String)
      async throws -> FineTuningJobObject
   {
      let request = try await OpenAIAPI.fineTuning(.retrieve(jobID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FineTuningJobObject.self, with: request)
   }

   func cancelFineTuningJobWith(
      id: String)
      async throws -> FineTuningJobObject
   {
      let request = try await OpenAIAPI.fineTuning(.cancel(jobID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FineTuningJobObject.self, with: request)
   }

   func listFineTuningEventsForJobWith(
      id: String,
      after lastEventId: String? = nil,
      limit: Int? = nil)
      async throws -> OpenAIResponse<FineTuningJobEventObject>
   {
      var queryItems: [URLQueryItem] = []
      if let lastEventId, let limit {
         queryItems = [.init(name: "after", value: lastEventId), .init(name: "limit", value: "\(limit)")]
      } else if let lastEventId {
         queryItems = [.init(name: "after", value: lastEventId)]
      } else if let limit {
         queryItems = [.init(name: "limit", value: "\(limit)")]
      }
      let request = try await OpenAIAPI.fineTuning(.events(jobID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<FineTuningJobEventObject>.self, with: request)
   }

   // MARK: Files

   func listFiles()
      async throws -> OpenAIResponse<FileObject>
   {
      let request = try await OpenAIAPI.file(.list).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<FileObject>.self, with: request)
   }

   func uploadFile(
      parameters: FileParameters)
      async throws -> FileObject
   {
      let request = try await OpenAIAPI.file(.upload).multiPartRequest(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FileObject.self, with: request)
   }

   func deleteFileWith(
      id: String)
      async throws -> FileObject.DeletionStatus
   {
      let request = try await OpenAIAPI.file(.delete(fileID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .delete, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FileObject.DeletionStatus.self, with: request)
   }

   func retrieveFileWith(
      id: String)
      async throws -> FileObject
   {
      let request = try await OpenAIAPI.file(.retrieve(fileID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: FileObject.self, with: request)
   }

   func retrieveContentForFileWith(
      id: String)
      async throws -> [[String: Any]]
   {
      let request = try await OpenAIAPI.file(.retrieveFileContent(fileID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetchContentsOfFile(request: request)
   }

   // MARK: Images

   func createImages(
      parameters: ImageCreateParameters)
      async throws -> OpenAIResponse<ImageObject>
   {
      let request = try await OpenAIAPI.images(.generations).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<ImageObject>.self,  with: request)
   }

   func editImage(
      parameters: ImageEditParameters)
      async throws -> OpenAIResponse<ImageObject>
   {
      let request = try await OpenAIAPI.images(.edits).multiPartRequest(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<ImageObject>.self, with: request)
   }

   func createImageVariations(
      parameters: ImageVariationParameters)
      async throws -> OpenAIResponse<ImageObject>
   {
      let request = try await OpenAIAPI.images(.variations).multiPartRequest(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<ImageObject>.self, with: request)
   }

   // MARK: Models

   func listModels()
      async throws -> OpenAIResponse<ModelObject>
   {
      let request = try await OpenAIAPI.model(.list).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<ModelObject>.self,  with: request)
   }

   func retrieveModelWith(
      id: String)
      async throws -> ModelObject
   {
      let request = try await OpenAIAPI.model(.retrieve(modelID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ModelObject.self,  with: request)
   }

   func deleteFineTuneModelWith(
      id: String)
      async throws -> ModelObject.DeletionStatus
   {
      let request = try await OpenAIAPI.model(.deleteFineTuneModel(modelID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .delete, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ModelObject.DeletionStatus.self,  with: request)
   }

   // MARK: Moderations

   func createModerationFromText(
      parameters: ModerationParameter<String>)
      async throws -> ModerationObject
   {
      let request = try await OpenAIAPI.moderations.request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ModerationObject.self, with: request)
   }

   func createModerationFromTexts(
      parameters: ModerationParameter<[String]>)
      async throws -> ModerationObject
   {
      let request = try await OpenAIAPI.moderations.request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ModerationObject.self, with: request)
   }

   // MARK: Assistants [BETA]

   func createAssistant(
      parameters: AssistantParameters)
      async throws -> AssistantObject
   {
      let request = try await OpenAIAPI.assistant(.create).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantObject.self, with: request)
   }

   func retrieveAssistant(
      id: String)
      async throws -> AssistantObject
   {
      let request = try await OpenAIAPI.assistant(.retrieve(assistantID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantObject.self, with: request)
   }

   func modifyAssistant(
      id: String,
      parameters: AssistantParameters)
      async throws -> AssistantObject
   {
      let request = try await OpenAIAPI.assistant(.modify(assistantID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantObject.self, with: request)
   }

   func deleteAssistant(
      id: String)
      async throws -> AssistantObject.DeletionStatus
   {
      let request = try await OpenAIAPI.assistant(.delete(assistantID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .delete, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantObject.DeletionStatus.self, with: request)
   }

   func listAssistants(
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<AssistantObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.assistant(.list).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<AssistantObject>.self, with: request)
   }

   // MARK: AssistantsFileObject [BETA]

   func createAssistantFile(
      assistantID: String,
      parameters: AssistantFileParamaters)
      async throws -> AssistantFileObject
   {
      let request = try await OpenAIAPI.assistantFile(.create(assistantID: assistantID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantFileObject.self, with: request)
   }

   func retrieveAssistantFile(
      assistantID: String,
      fileID: String)
      async throws -> AssistantFileObject
   {
      let request = try await OpenAIAPI.assistantFile(.retrieve(assistantID: assistantID, fileID: fileID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantFileObject.self, with: request)
   }

   func deleteAssistantFile(
      assistantID: String,
      fileID: String)
      async throws -> AssistantFileObject.DeletionStatus
   {
      let request = try await OpenAIAPI.assistantFile(.delete(assistantID: assistantID, fileID: fileID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .delete, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: AssistantFileObject.DeletionStatus.self, with: request)
   }

   func listAssistantFiles(
      assistantID: String,
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<AssistantFileObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.assistant(.list).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<AssistantFileObject>.self, with: request)
   }

   // MARK: Thread [BETA]

   func createThread(
      parameters: CreateThreadParameters)
      async throws -> ThreadObject
   {
      let request = try await OpenAIAPI.thread(.create).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ThreadObject.self, with: request)
   }

   func retrieveThread(id: String)
      async throws -> ThreadObject
   {
      let request = try await OpenAIAPI.thread(.retrieve(threadID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ThreadObject.self, with: request)
   }

   func modifyThread(
      id: String,
      parameters: ModifyThreadParameters)
      async throws -> ThreadObject
   {
      let request = try await OpenAIAPI.thread(.modify(threadID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ThreadObject.self, with: request)
   }

   func deleteThread(
      id: String)
      async throws -> ThreadObject.DeletionStatus
   {
      let request = try await OpenAIAPI.thread(.delete(threadID: id)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .delete, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: ThreadObject.DeletionStatus.self, with: request)
   }

   // MARK: Message [BETA]

   func createMessage(
      threadID: String,
      parameters: MessageParameter)
      async throws -> MessageObject
   {
      let request = try await OpenAIAPI.message(.create(threadID: threadID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: MessageObject.self, with: request)
   }

   func retrieveMessage(
      threadID: String,
      messageID: String)
      async throws -> MessageObject
   {
      let request = try await OpenAIAPI.message(.retrieve(threadID: threadID, messageID: messageID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: MessageObject.self, with: request)
   }

   func modifyMessage(
      threadID: String,
      messageID: String,
      parameters: ModifyMessageParameters)
      async throws -> MessageObject
   {
      let request = try await OpenAIAPI.message(.modify(threadID: threadID, messageID: messageID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: MessageObject.self, with: request)
   }

   func listMessages(
      threadID: String,
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<MessageObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.message(.list(threadID: threadID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<MessageObject>.self, with: request)
   }

   // MARK: Message File [BETA]

   func retrieveMessageFile(
      threadID: String,
      messageID: String,
      fileID: String)
      async throws -> MessageFileObject
   {
      let request = try await OpenAIAPI.messageFile(.retrieve(threadID: threadID, messageID: messageID, fileID: fileID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: MessageFileObject.self, with: request)
   }

   func listMessageFiles(
      threadID: String,
      messageID: String,
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<MessageFileObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.messageFile(.list(threadID: threadID, messageID: messageID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<MessageFileObject>.self, with: request)
   }

   func createRun(
      threadID: String,
      parameters: RunParameter)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.create(threadID: threadID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   func retrieveRun(
      threadID: String,
      runID: String)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.retrieve(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   func modifyRun(
      threadID: String,
      runID: String,
      parameters: ModifyRunParameters)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.modify(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   func listRuns(
      threadID: String,
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<RunObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.run(.list(threadID: threadID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<RunObject>.self, with: request)
   }

   func cancelRun(
      threadID: String,
      runID: String)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.cancel(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   func submitToolOutputsToRun(
      threadID: String,
      runID: String,
      parameters: RunToolsOutputParameter)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.submitToolOutput(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   func createThreadAndRun(
      parameters: CreateThreadAndRunParameter)
      async throws -> RunObject
   {
      let request = try await OpenAIAPI.run(.createThreadAndRun).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunObject.self, with: request)
   }

   // MARK: Run Step [BETA]

   func retrieveRunstep(
      threadID: String,
      runID: String,
      stepID: String)
      async throws -> RunStepObject
   {
      let request = try await OpenAIAPI.runStep(.retrieve(threadID: threadID, runID: runID, stepID: stepID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: RunStepObject.self, with: request)
   }

   func listRunSteps(
      threadID: String,
      runID: String,
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws -> OpenAIResponse<RunStepObject>
   {
      var queryItems: [URLQueryItem] = []
      if let limit {
         queryItems.append(.init(name: "limit", value: "\(limit)"))
      }
      if let order {
         queryItems.append(.init(name: "order", value: order))
      }
      if let after {
         queryItems.append(.init(name: "after", value: after))
      }
      if let before {
         queryItems.append(.init(name: "before", value: before))
      }
      let request = try await OpenAIAPI.runStep(.list(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .get, queryItems: queryItems, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetch(type: OpenAIResponse<RunStepObject>.self, with: request)
   }

   func createRunStream(
      threadID: String,
      parameters: RunParameter)
      async throws -> AsyncThrowingStream<AssistantStreamEvent, Error>
   {
      var runParameters = parameters
      runParameters.stream = true
      let request = try await OpenAIAPI.run(.create(threadID: threadID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: runParameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetchAssistantStreamEvents(with: request)
   }

   func createThreadAndRunStream(
      parameters: CreateThreadAndRunParameter)
      async throws -> AsyncThrowingStream<AssistantStreamEvent, Error> {
      var runParameters = parameters
      runParameters.stream = true
      let request = try await OpenAIAPI.run(.createThreadAndRun).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, deviceCheckBypass: deviceCheckBypass)
      return try await fetchAssistantStreamEvents(with: request)
   }

   func submitToolOutputsToRunStream(
      threadID: String,
      runID: String,
      parameters: RunToolsOutputParameter)
      async throws -> AsyncThrowingStream<AssistantStreamEvent, Error>
   {
      var runToolsOutputParameter = parameters
      runToolsOutputParameter.stream = true
      let request = try await OpenAIAPI.run(.submitToolOutput(threadID: threadID, runID: runID)).request(aiproxyPartialKey: partialKey, organizationID: organizationID, method: .post, params: parameters, betaHeaderField: Self.assistantsBeta, deviceCheckBypass: deviceCheckBypass)
      return try await fetchAssistantStreamEvents(with: request)
   }
}


