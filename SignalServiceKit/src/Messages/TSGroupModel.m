//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSGroupModel.h"
#import "FunctionalUtil.h"
#import "TSStorageManager.h"
#import "SignalRecipient.h"

NSString *const GroupUpdateTypeSting = @"updateTypeString";
NSString *const GroupInfoString = @"updateInfoString";

@implementation TSGroupModel

#if TARGET_OS_IOS
- (instancetype)initWithTitle:(NSString *)title
                    memberIds:(NSArray<NSString *> *)memberIds
                        image:(UIImage *)image
                      groupId:(NSData *)groupId
{
    _groupName              = title;
    _groupMemberIds         = [memberIds copy];
    _groupImage = image; // image is stored in DB
    _groupId                = groupId;

    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToGroupModel:other];
}

- (BOOL)isEqualToGroupModel:(TSGroupModel *)other {
    if (self == other)
        return YES;
    if (![_groupId isEqualToData:other.groupId]) {
        return NO;
    }
    if (![_groupName isEqual:other.groupName]) {
        return NO;
    }
    if (!(_groupImage != nil && other.groupImage != nil &&
          [UIImagePNGRepresentation(_groupImage) isEqualToData:UIImagePNGRepresentation(other.groupImage)])) {
        return NO;
    }
    NSMutableArray *compareMyGroupMemberIds = [NSMutableArray arrayWithArray:_groupMemberIds];
    [compareMyGroupMemberIds removeObjectsInArray:other.groupMemberIds];
    if ([compareMyGroupMemberIds count] > 0) {
        return NO;
    }
    return YES;
}

- (NSDictionary *)getInfoAboutUpdateTo:(TSGroupModel *)newModel contactsManager:(id<ContactsManagerProtocol>)contactsManager {
    NSString *updateTypeString = @"";
    NSString *updatedGroupInfoString = @"";

    if (self == newModel) {
        return @{GroupUpdateTypeSting: NSLocalizedString(@"GROUP_UPDATED", @""),
                 GroupInfoString: updatedGroupInfoString
                 };
    }

    if (![_groupName isEqual:newModel.groupName]) {
        updateTypeString = [updateTypeString
                            stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"GROUP_TITLE_CHANGED", @""),
                                                     newModel.groupName]];
        updatedGroupInfoString = newModel.groupName;
    }

    if (_groupImage != nil && newModel.groupImage != nil &&
        !([UIImagePNGRepresentation(_groupImage) isEqualToData:UIImagePNGRepresentation(newModel.groupImage)])) {
        updateTypeString =
        [updateTypeString stringByAppendingString:NSLocalizedString(@"GROUP_AVATAR_CHANGED", @"")];
    }

    if ([updateTypeString length] == 0) {
        updateTypeString = NSLocalizedString(@"GROUP_UPDATED", @"");
    }

    NSSet *oldMembers = [NSSet setWithArray:_groupMemberIds];
    NSSet *newMembers = [NSSet setWithArray:newModel.groupMemberIds];

    NSMutableSet *membersWhoJoined = [NSMutableSet setWithSet:newMembers];
    [membersWhoJoined minusSet:oldMembers];

    NSMutableSet *membersWhoLeft = [NSMutableSet setWithSet:oldMembers];
    [membersWhoLeft minusSet:newMembers];

    if ([membersWhoLeft count] > 0) {
        NSString *oldMembersString = [[membersWhoLeft allObjects] componentsJoinedByString:@", "];
        updateTypeString = [updateTypeString
                            stringByAppendingString:[NSString
                                                     stringWithFormat:NSLocalizedString(@"GROUP_MEMBER_LEFT", @""),
                                                     oldMembersString]];
        updatedGroupInfoString = oldMembersString;
    }

    if ([membersWhoJoined count] > 0) {
        updateTypeString = [NSString stringWithFormat:NSLocalizedString(@"GROUP_MEMBER_JOINED", @""),
                            [membersWhoJoined.allObjects componentsJoinedByString:@", "]];
        updatedGroupInfoString = [membersWhoJoined.allObjects componentsJoinedByString:@", "];
    }

    return @{GroupUpdateTypeSting: updateTypeString,
             GroupInfoString: updatedGroupInfoString
             };
}

#endif

@end
