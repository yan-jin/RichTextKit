//
//  RichTextKeyboardToolbar.swift
//  RichTextKit
//
//  Created by Daniel Saidi on 2022-12-14.
//  Copyright © 2022-2024 Daniel Saidi. All rights reserved.
//

#if iOS || macOS || os(visionOS)
import SwiftUI
#if iOS
import PhotosUI
#endif

/**
 This toolbar can be added above an iOS keyboard, to provide
 rich text formatting in a compact form.

 This toolbar is needed since the ``RichTextEditor`` can not
 use a `toolbar` modifier with `.keyboard` placement:

 ```swift
 RichTextEditor(text: $text, context: context)
     .toolbar {
         ToolbarItemGroup(placement: .keyboard) {
             ....
         }
     }
 ```

 Instead, add this toolbar below a ``RichTextEditor`` to let
 it automatically show when the text editor is edited in iOS.

 You can inject additional leading and trailing buttons, and
 customize the format sheet that is presented when users tap
 format button:

 ```swift
 VStack {
    RichTextEditor(...)
    RichTextKeyboardToolbar(
        context: context,
        leadingButtons: {},
        trailingButtons: {},
        formatSheet: { $0 }
    )
 }
 ```

 These view builders provide you with standard views. Return
 `$0` to use these standard views, or return any custom view
 that you want to use instead.

 You can configure and style the view by applying its config
 and style view modifiers to your view hierarchy:

 ```swift
 VStack {
    RichTextEditor(...)
    RichTextKeyboardToolbar(...)
 }
 .richTextKeyboardToolbarStyle(...)
 .richTextKeyboardToolbarConfig(...)
 ```

 For more information, see ``RichTextKeyboardToolbarConfig``
 and ``RichTextKeyboardToolbarStyle``.
 */
public struct RichTextKeyboardToolbar<LeadingButtons: View, TrailingButtons: View, FormatSheet: View>: View {

    /**
     Create a rich text keyboard toolbar.

     - Parameters:
       - context: The context to affect.
       - leadingButtons: The leading buttons to place after the leading actions.
       - trailingButtons: The trailing buttons to place before the trailing actions.
       - formatSheet: The rich text format sheet to use, by default ``RichTextFormat/Sheet``.
     */
    public init(
        context: RichTextContext,
        @ViewBuilder leadingButtons: @escaping (StandardLeadingButtons) -> LeadingButtons,
        @ViewBuilder trailingButtons: @escaping (StandardTrailingButtons) -> TrailingButtons,
        @ViewBuilder formatSheet: @escaping (StandardFormatSheet) -> FormatSheet
    ) {
        self._context = ObservedObject(wrappedValue: context)
        self.leadingButtons = leadingButtons
        self.trailingButtons = trailingButtons
        self.formatSheet = formatSheet
    }

    public typealias StandardLeadingButtons = EmptyView
    public typealias StandardTrailingButtons = EmptyView
    public typealias StandardFormatSheet = RichTextFormat.Sheet

    private let leadingButtons: (StandardLeadingButtons) -> LeadingButtons
    private let trailingButtons: (StandardTrailingButtons) -> TrailingButtons
    private let formatSheet: (StandardFormatSheet) -> FormatSheet

    @ObservedObject
    private var context: RichTextContext

    @State
    private var isFormatSheetPresented = false

    @State
    private var isPhotosPickerPresented = false

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.richTextKeyboardToolbarConfig)
    private var config

    @Environment(\.richTextKeyboardToolbarStyle)
    private var style
    
    @Namespace var namespace

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10.0) {
                HStack(spacing: style.itemSpacing) {
                    leadingViews
                    centerViews
                    trailingViews
                }
            }
            .environment(\.sizeCategory, .medium)
            .frame(height: style.toolbarHeight)
            //.overlay(Divider(), alignment: .bottom)
            .accentColor(.primary)
            .background(
                .clear
                /*
                Color.primary.colorInvert()
                    .overlay(Color.white.opacity(0.2))
                    .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 0)
                 */
            )
            .opacity(shouldDisplayToolbar ? 1 : 0)
            //.offset(y: shouldDisplayToolbar ? 0 : style.toolbarHeight)
            .frame(height: shouldDisplayToolbar ? nil : 0)
            .sheet(isPresented: $isFormatSheetPresented) {
                formatSheet(
                    .init(context: context)
                )
                .prefersMediumSize()
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: style.itemSpacing) {
                    leadingViews
                    centerViews
                    trailingViews
                }
                .padding(10)
            }
            //.environment(\.sizeCategory, .medium)
            .frame(height: style.toolbarHeight)
            //.overlay(Divider(), alignment: .bottom)
            .accentColor(.primary)
            .background(
                .clear
                /*
                Color.primary.colorInvert()
                    .overlay(Color.white.opacity(0.2))
                    .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 0)
                 */
            )
            .opacity(shouldDisplayToolbar ? 1 : 0)
            //.offset(y: shouldDisplayToolbar ? 0 : style.toolbarHeight)
            .frame(height: shouldDisplayToolbar ? nil : 0)
            .sheet(isPresented: $isFormatSheetPresented) {
                formatSheet(
                    .init(context: context)
                )
                .prefersMediumSize()
            }
        }
    }
}

private extension View {

    @ViewBuilder
    func prefersMediumSize() -> some View {
        #if macOS
        self
        #else
        if #available(iOS 16, *) {
            self.presentationDetents([.medium])
        } else {
            self
        }
        #endif
    }
}

private extension RichTextKeyboardToolbar {

    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
}

private extension RichTextKeyboardToolbar {

    var divider: some View {
        Divider()
            .frame(height: 25)
    }

    @ViewBuilder
    var leadingViews: some View {
        HStack(spacing: 0) {
            ForEach(config.leadingActions) { action in
                RichTextAction.Button(
                    action: action,
                    context: context,
                    fillVertically: true
                )
                .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(id: "toolbar", namespace: namespace)
            }
        }
        .fixedSize(horizontal: false, vertical: true)

        leadingButtons(StandardLeadingButtons())
    }
    
    @ViewBuilder
    var centerViews: some View {
        
        if config.displayFormatSheetButton {
           Button(action: presentFormatSheet) {
               Image.richTextFormat
                   .contentShape(Rectangle())
           }
           .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
           .conditionalGlassEffect(id: "toolbar", namespace: namespace)
        }
        
        if #available(iOS 16.0, *) {
            PhotosPickerButton(context: context)
                .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                .conditionalGlassEffect(id: "toolbar", namespace: namespace)
        }
    }

    @ViewBuilder
    var trailingViews: some View {
        /*
        Picker(
            forValue: \.alignment,
            in: context
        ) {
            Text(RTKL10n.textAlignment.text)
        } valueLabel: {
            $0.defaultLabel
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
        .keyboardShortcutsOnly(if: isCompact)
         */

        trailingButtons(StandardTrailingButtons())

        HStack(spacing: 0) {
            ForEach(config.trailingActions) { action in
                RichTextAction.Button(
                    action: action,
                    context: context,
                    fillVertically: true
                )
                .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(id: "toolbar", namespace: namespace)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension View {

    @ViewBuilder
    func keyboardShortcutsOnly(
        if condition: Bool = true
    ) -> some View {
        if condition {
            self.hidden()
                .frame(width: 0)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func conditionalGlassEffect(id: String, namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive())
                .glassEffectUnion(id: id, namespace: namespace)
            
        } else {
            self
        }
    }
}

private extension RichTextKeyboardToolbar {

    var shouldDisplayToolbar: Bool { context.isEditingText || config.alwaysDisplayToolbar }
}

private extension RichTextKeyboardToolbar {

    func presentFormatSheet() {
        isFormatSheetPresented = true
    }
}

#if iOS
@available(iOS 16.0, *)
private struct PhotosPickerButton: View {
    let context: RichTextContext
    
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isPhotosPickerPresented = false
    
    var body: some View {
        Button(action: { isPhotosPickerPresented = true }) {
            Image.richTextInsertImage
                .contentShape(Rectangle())
        }
        .photosPicker(
            isPresented: $isPhotosPickerPresented,
            selection: $selectedPhotoItems,
            maxSelectionCount: 1,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItems) { items in
            handleSelectedPhotos(items)
        }
    }
    
    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = ImageRepresentable(data: data) {
                    await MainActor.run {
                        let index = context.selectedRange.location
                        let insertion = RichTextInsertion<ImageRepresentable>.image(image, at: index, moveCursor: true)
                        context.handle(.pasteImage(insertion))
                    }
                }
            }
            
            await MainActor.run {
                selectedPhotoItems.removeAll()
            }
        }
    }
}
#endif

#Preview {

    struct Preview: View {

        @State
        private var text = NSAttributedString(string: "")

        @StateObject
        private var context = RichTextContext()

        var body: some View {
            VStack(spacing: 0) {
                RichTextEditor(text: $text, context: context)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding()
                    .background(Color.gray.ignoresSafeArea())
                RichTextKeyboardToolbar(
                    context: context,
                    leadingButtons: {_ in },
                    trailingButtons: {_ in },
                    formatSheet: { $0 }
                )
            }
            .richTextKeyboardToolbarConfig(.init(
                alwaysDisplayToolbar: false,
                leadingActions: [],
                trailingActions: [.dismissKeyboard, .print]
            ))
        }
    }

    return Preview()
}
#endif
